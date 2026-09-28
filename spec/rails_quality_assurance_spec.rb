# frozen_string_literal: true

require 'rails_quality_assurance'
require 'rails_quality_assurance/simplecov/helper'
require 'simplecov'
require 'rake'
require 'rubocop'
require 'yaml'

RSpec.describe RailsQualityAssurance do
  def in_fresh_rake_application
    original = Rake.application
    Rake.application = Rake::Application.new
    yield
  ensure
    Rake.application = original
  end

  def load_quality_assurance_tasks
    load File.join(described_class.root, 'lib/tasks/quality_assurance.rake')
  end

  describe 'VERSION' do
    it 'is a semantic version string' do
      expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end

  describe 'paths' do
    it 'locates the gem root' do
      expect(File.directory?(described_class.root)).to be(true)
    end

    it 'locates rubocop.yml' do
      expect(File.exist?(described_class.rubocop_config_path)).to be(true)
    end

    it 'locates reek.yml' do
      expect(File.exist?(described_class.reek_config_path)).to be(true)
    end

    it 'locates the packaged biome default' do
      expect(File.exist?(described_class.biome_config_path)).to be(true)
    end

    it 'locates the packaged stylelint default' do
      expect(File.exist?(described_class.stylelint_config_path)).to be(true)
    end

    it 'keeps the parallel spec lock under tmp/qa' do
      expect(described_class.spec_lock_path).to eq(File.join('tmp', 'qa', 'spec_parallel.lock'))
    end
  end

  describe 'packaged rubocop.yml' do
    let(:raw) { YAML.unsafe_load_file(described_class.rubocop_config_path) }
    let(:config) { RuboCop::ConfigLoader.load_file(described_class.rubocop_config_path) }

    it 'declares all required plugins' do
      expect(raw['plugins']).to contain_exactly(
        'rubocop-performance', 'rubocop-rspec', 'rubocop-rspec_rails',
        'rubocop-capybara', 'rubocop-factory_bot', 'rubocop-rubycw',
        'rubocop-migration', 'rubocop-rails'
      )
    end

    it 'merges Exclude so projects can add their own' do
      expect(config.dig('inherit_mode', 'merge')).to eq(['Exclude'])
    end

    it 'targets Ruby 4.0' do
      expect(config.dig('AllCops', 'TargetRubyVersion')).to eq(4.0)
    end

    it 'keeps metric thresholds' do
      expect(config.dig('Metrics/AbcSize', 'Max')).to eq(35)
      expect(config.dig('Metrics/MethodLength', 'Max')).to eq(30)
      expect(config.dig('Metrics/ClassLength', 'Max')).to eq(150)
      expect(config.dig('Layout/LineLength', 'Max')).to eq(120)
    end

    it 'keeps style decisions' do
      expect(config.dig('Style/HashSyntax', 'EnforcedShorthandSyntax')).to eq('always')
      expect(config.dig('Style/Documentation', 'Enabled')).to be(false)
    end

    it 'uses the Capybara/RSpec department for NegationMatcherAfterVisit' do
      expect(raw).to have_key('Capybara/RSpec/NegationMatcherAfterVisit')
      expect(raw).not_to have_key('Capybara/NegationMatcherAfterVisit')
    end
  end

  describe 'gem dependencies' do
    let(:spec) { Gem::Specification.load(File.join(described_class.root, 'rails-quality-assurance.gemspec')) }

    it 'owns the full QA toolchain as runtime dependencies' do
      runtime = spec.runtime_dependencies.map(&:name)
      expect(runtime).to include(
        'factory_bot_rails', 'faker', 'parallel_tests', 'rspec-rails',
        'simplecov', 'simplecov-lcov', 'webmock', 'capybara',
        'capybara-playwright-driver', 'playwright-ruby-client', 'brakeman',
        'bundler-audit', 'flay', 'reek', 'rubocop'
      )
    end

    it 'registers the parallel_tests rake tasks' do
      in_fresh_rake_application do
        load Gem.find_files('parallel_tests/tasks.rb').first
        expect(Rake::Task.task_defined?('parallel:create')).to be(true)
      end
    end

    it 'namespaces its tasks under qa: without hijacking app tasks' do
      in_fresh_rake_application do
        load_quality_assurance_tasks

        aggregate_failures do
          expect(Rake::Task.task_defined?('qa:lint')).to be(true)
          expect(Rake::Task.task_defined?('qa:reek')).to be(true)
          expect(Rake::Task.task_defined?('qa:audit:gems')).to be(true)
          expect(Rake::Task.task_defined?('qa:audit:importmap')).to be(true)
          expect(Rake::Task.task_defined?('qa:audit:npm')).to be(true)
          expect(Rake::Task.task_defined?('qa:lint:biome')).to be(true)
          expect(Rake::Task.task_defined?('spec:parallel')).to be(true)
        end
        expect(Rake::Task.task_defined?('lint')).to be(false)
      end
    end

    it 'does not boot the Rails environment for shell-based checks' do
      in_fresh_rake_application do
        load_quality_assurance_tasks

        %w[qa:rubocop qa:reek qa:flay qa:brakeman qa:audit qa:audit:gems qa:audit:importmap
           qa:audit:npm qa:lint:biome qa:lint:stylelint].each do |name|
          expect(Rake::Task[name].prerequisites).not_to include('environment'),
                                                        "#{name} must not require :environment"
        end
      end
    end

    it 'serializes the parallel spec task behind the run lock' do
      in_fresh_rake_application do
        load_quality_assurance_tasks
        Rake::Task.define_task('environment')

        config = instance_double(RailsQualityAssurance::ParallelSpecConfig, processors: 2, parallel_options: '')
        allow(RailsQualityAssurance::ParallelSpecConfig).to receive(:from_env).and_return(config)

        commands = []
        allow(TOPLEVEL_BINDING.receiver).to receive(:sh) { |command| commands << command }
        allow(RailsQualityAssurance::RunLock).to receive(:guard) do |_path, command:, &block|
          commands << command
          block.call
        end

        Rake::Task['spec:parallel'].invoke

        expect(commands).to include('spec:parallel')
      end
    end

    it 'skips the importmap audit when the app has no importmap' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('config/importmap.rb').and_return(false)

      expect(described_class.importmap_audit_command).to be_nil
    end

    it 'uses the app binstub for the importmap audit when present' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('config/importmap.rb').and_return(true)
      allow(File).to receive(:exist?).with('bin/importmap').and_return(true)

      expect(described_class.importmap_audit_command).to eq('bin/importmap audit')
    end

    it 'falls back to importmap-rails when the app has no binstub' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('config/importmap.rb').and_return(true)
      allow(File).to receive(:exist?).with('bin/importmap').and_return(false)

      expect(described_class.importmap_audit_command).to include('require "importmap/commands"')
    end
  end

  describe '.npm_audit_command' do
    def stub_lockfiles(present)
      allow(File).to receive(:exist?).and_call_original
      %w[package-lock.json yarn.lock pnpm-lock.yaml].each do |lockfile|
        allow(File).to receive(:exist?).with(lockfile).and_return(present.include?(lockfile))
      end
    end

    it 'returns nil when the app has no JavaScript lockfile' do
      stub_lockfiles([])

      expect(described_class.npm_audit_command).to be_nil
    end

    it 'runs npm audit when a package-lock.json is present' do
      stub_lockfiles(%w[package-lock.json])

      expect(described_class.npm_audit_command).to eq('npm audit --audit-level=high')
    end

    it 'runs yarn audit and masks high and critical severities for yarn.lock' do
      stub_lockfiles(%w[yarn.lock])

      expect(described_class.npm_audit_command).to eq('yarn audit; status=$?; [ $((status & 24)) -eq 0 ]')
    end

    it 'runs pnpm audit when a pnpm-lock.yaml is present' do
      stub_lockfiles(%w[pnpm-lock.yaml])

      expect(described_class.npm_audit_command).to eq('pnpm audit --audit-level high')
    end

    it 'prefers package-lock.json when multiple lockfiles exist' do
      stub_lockfiles(%w[package-lock.json yarn.lock pnpm-lock.yaml])

      expect(described_class.npm_audit_command).to start_with('npm audit')
    end
  end

  describe 'SimpleCov parallel merge ownership' do
    let(:helper) { File.read(File.join(described_class.root, 'lib/rails_quality_assurance/simplecov/helper.rb')) }

    it 'claims finalization so thresholds are enforced once in parallel runs' do
      expect(helper).to include('finalize_merge true')
    end

    it 'requires a SimpleCov line that provides finalize_merge' do
      simplecov = Gem::Specification.find_by_name('simplecov')
      expect(Gem::Requirement.new('~> 1.3.0')).to be_satisfied_by(simplecov.version)
    end

    it 'uses the non-deprecated SimpleCov.skip API' do
      expect(helper).not_to match(/\badd_filter\b/)
    end

    describe 'SimpleCovHelper' do
      subject(:helper_class) { RailsQualityAssurance::SimpleCovHelper }

      describe '.apply_thresholds' do
        let(:simplecov) { class_double(SimpleCov) }
        let(:existing_minimum) { {} }
        let(:existing_drop) { {} }

        before do
          stub_const('SimpleCov', simplecov)
          allow(simplecov).to receive_messages(
            minimum_coverage: existing_minimum,
            maximum_coverage_drop: existing_drop
          )
        end

        it 'applies the gem defaults when nothing is configured' do
          helper_class.apply_thresholds(env: {})

          expect(simplecov).to have_received(:minimum_coverage).with(line: 100, branch: 100)
          expect(simplecov).to have_received(:maximum_coverage_drop).with({})
        end

        it 'lets the environment override existing thresholds' do
          env = { 'MINIMUM_LINE_COVERAGE' => '95', 'MAXIMUM_COVERAGE_DROP' => '5' }
          allow(simplecov).to receive_messages(
            minimum_coverage: { line: 80, branch: 70 },
            maximum_coverage_drop: { line: 2 }
          )

          helper_class.apply_thresholds(env:)

          expect(simplecov).to have_received(:minimum_coverage).with(line: 95, branch: 70)
          expect(simplecov).to have_received(:maximum_coverage_drop).with(line: 5)
        end

        it 'keeps the values a project configured in .simplecov' do
          allow(simplecov).to receive(:minimum_coverage).and_return({ line: 80, branch: 70 })

          helper_class.apply_thresholds(env: {})

          expect(simplecov).to have_received(:minimum_coverage).with(line: 80, branch: 70)
        end
      end

      describe '.parallel_run?' do
        %w[TEST_ENV_NUMBER PARALLEL_TEST_GROUPS PARALLEL_PID_FILE].each do |key|
          it "is true when #{key} is set" do
            allow(ENV).to receive(:key?).and_call_original
            allow(ENV).to receive(:key?).with(key).and_return(true)

            expect(helper_class.parallel_run?).to be(true)
          end
        end

        it 'is false for a plain single-process run' do
          allow(ENV).to receive(:key?).and_call_original

          expect(helper_class.parallel_run?).to be(false)
        end
      end

      describe '.filtered_run?' do
        def stub_parallel_env(parallel)
          allow(ENV).to receive(:key?).and_call_original
          %w[TEST_ENV_NUMBER PARALLEL_TEST_GROUPS PARALLEL_PID_FILE].each do |key|
            allow(ENV).to receive(:key?).with(key).and_return(parallel)
          end
        end

        it 'never reports a parallel worker as filtered, even when it runs a single file' do
          stub_parallel_env(true)
          allow(RSpec.configuration).to receive(:files_to_run).and_return([double])

          expect(helper_class.filtered_run?).to be(false)
        end

        it 'reports a single-file single-process run as filtered' do
          stub_parallel_env(false)
          allow(RSpec.configuration).to receive_messages(
            files_to_run: [double], only_failures?: false, inclusion_filter: double(rules: [])
          )

          expect(helper_class.filtered_run?).to be(true)
        end

        it 'reports an only-failures run as filtered' do
          stub_parallel_env(false)
          allow(RSpec.configuration).to receive_messages(
            files_to_run: [double, double], only_failures?: true, inclusion_filter: double(rules: [])
          )

          expect(helper_class.filtered_run?).to be(true)
        end

        it 'reports an example-filtered run as filtered, so coverage is not enforced against a subset' do
          stub_parallel_env(false)
          allow(RSpec.configuration).to receive_messages(
            files_to_run: [double, double], only_failures?: false, inclusion_filter: double(rules: [double])
          )

          expect(helper_class.filtered_run?).to be(true)
        end

        it 'reports a full single-process run as unfiltered' do
          stub_parallel_env(false)
          allow(RSpec.configuration).to receive_messages(
            files_to_run: [double, double], only_failures?: false, inclusion_filter: double(rules: [])
          )

          expect(helper_class.filtered_run?).to be(false)
        end
      end
    end
  end
end
