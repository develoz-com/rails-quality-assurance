# frozen_string_literal: true

require 'rails_quality_assurance'
require 'parallel_tests/tasks'

# Resolves the JavaScript quality-assurance CLI: the app's installed copy when
# present, otherwise the published package through npx. Keeps the frontend gates
# working without an app-side install.
def js_qa_command
  local = File.join('node_modules', '.bin', 'qa')
  return local if File.exist?(local)

  'npx --yes @develoz/quality-assurance@~0.3'
end

namespace :qa do
  desc 'Run all quality assurance checks (RuboCop, Reek, Flay, Brakeman, bundler-audit, importmap-audit, JS audit)'
  task lint: %w[qa:rubocop qa:reek qa:flay qa:brakeman qa:audit qa:audit:importmap qa:audit:npm]

  desc 'Run RuboCop'
  task :rubocop do
    sh 'bundle exec rubocop'
  end

  desc 'Run Reek code smell detection'
  task :reek do
    config = File.exist?('.reek.yml') ? '' : "-c #{RailsQualityAssurance.reek_config_path}"
    sh "bundle exec reek #{config} app lib"
  end

  desc 'Run Flay structural code duplication analysis'
  task :flay do
    mass = ENV.fetch('FLAY_MASS', '300')
    output = `bundle exec flay --mass #{mass} app lib`
    puts output
    abort 'Flay detected structural duplication' unless output.include?('Total score (lower is better) = 0')
  end

  desc 'Run Brakeman static security analysis'
  task :brakeman do
    sh 'bundle exec brakeman --quiet --no-pager --exit-on-warn --exit-on-error'
  end

  namespace :audit do
    desc 'Run Bundler Audit for vulnerable gems'
    task :gems do
      sh 'bundle exec bundle audit check --update'
    end

    desc 'Run Importmap Audit for vulnerable npm packages'
    task :importmap do
      command = RailsQualityAssurance.importmap_audit_command
      sh command if command
    end

    desc 'Run the JavaScript dependency audit via the JS quality-assurance CLI'
    task :npm do
      next unless File.exist?('package.json')

      sh "#{js_qa_command} audit"
    end
  end

  desc 'Run Bundler Audit for vulnerable gems'
  task audit: 'qa:audit:gems'

  namespace :lint do
    desc 'Run Biome (format + lint) through the JS quality-assurance CLI'
    task :biome do
      sh "#{js_qa_command} lint"
    end

    desc 'Run Stylelint through the JS quality-assurance CLI'
    task :stylelint do
      sh "#{js_qa_command} styles"
    end

    desc 'Run the Biome code-smell rules (warnings fail)'
    task :smells do
      sh "#{js_qa_command} smells"
    end

    desc 'Detect copied JavaScript/TypeScript with jscpd'
    task :duplication do
      sh "#{js_qa_command} duplication"
    end

    desc 'Type-check TypeScript with tsc (runs when the app has TypeScript)'
    task :typecheck do
      sh "#{js_qa_command} typecheck"
    end

    desc 'Find unused files, exports and dependencies with knip'
    task :deadcode do
      sh "#{js_qa_command} deadcode"
    end

    desc 'Enforce architecture boundaries with dependency-cruiser'
    task :boundaries do
      sh "#{js_qa_command} boundaries"
    end
  end

  desc 'Run the frontend quality gates (Biome, Stylelint, smells, duplication)'
  task frontend: %w[qa:lint:biome qa:lint:stylelint qa:lint:smells qa:lint:duplication]

  desc 'Run all CI checks'
  task ci: %w[qa:lint qa:frontend spec:parallel]
end

namespace :spec do
  desc 'Run specs in parallel with system specs isolated'
  task parallel: :environment do
    ENV['PARALLEL_TEST_FIRST_IS_1'] ||= 'true'
    config = RailsQualityAssurance::ParallelSpecConfig.from_env
    test_options = ENV.fetch('PARALLEL_SPEC_OPTIONS', nil)

    options = config.parallel_options
    options = "#{options} --test-options=\"#{test_options}\"" if test_options

    RailsQualityAssurance::RunLock.guard(RailsQualityAssurance.spec_lock_path, command: 'spec:parallel') do
      # Each phase runs in its own rake process: parallel_tests shells out to `$0`
      # to load a schema per worker, which only works when `$0` is a rake runner.
      sh "bundle exec rake parallel:create[#{config.processors}]"
      sh "bundle exec rake parallel:load_schema[#{config.processors}]"
      sh "bundle exec parallel_rspec spec/ -n #{config.processors} #{options}"
    end
  end
end
