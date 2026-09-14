# frozen_string_literal: true

require 'json'
require 'rails_quality_assurance'
require 'parallel_tests/tasks'

def npm_script?(name)
  return false unless File.exist?('package.json')

  JSON.parse(File.read('package.json')).fetch('scripts', {}).key?(name)
rescue JSON::ParserError
  false
end

namespace :qa do
  desc 'Run all quality assurance checks (RuboCop, Reek, Flay, Brakeman, bundler-audit)'
  task lint: %w[qa:rubocop qa:reek qa:flay qa:brakeman qa:audit]

  desc 'Run RuboCop'
  task rubocop: :environment do
    sh 'bundle exec rubocop'
  end

  desc 'Run Reek code smell detection'
  task reek: :environment do
    config = File.exist?('.reek.yml') ? '' : "-c #{RailsQualityAssurance.reek_config_path}"
    sh "bundle exec reek #{config} app lib"
  end

  desc 'Run Flay structural code duplication analysis'
  task flay: :environment do
    mass = ENV.fetch('FLAY_MASS', '300')
    output = `bundle exec flay --mass #{mass} app lib`
    puts output
    abort 'Flay detected structural duplication' unless output.include?('Total score (lower is better) = 0')
  end

  desc 'Run Brakeman static security analysis'
  task brakeman: :environment do
    sh 'bundle exec brakeman --quiet --no-pager --exit-on-warn --exit-on-error'
  end

  desc 'Run Bundler Audit for vulnerable gems'
  task audit: :environment do
    sh 'bundle exec bundle audit check --update'
  end

  namespace :lint do
    desc 'Run BiomeJS on JS/TS/JSON'
    task biome: :environment do
      if npm_script?('biome')
        sh 'npm run biome'
      else
        config = File.exist?('biome.json') ? '' : "--config-path #{RailsQualityAssurance.biome_config_path}"
        sh "npx --no-install @biomejs/biome check #{config}"
      end
    end

    desc 'Run Stylelint on CSS'
    task stylelint: :environment do
      if npm_script?('stylelint')
        sh 'npm run stylelint'
      else
        config = File.exist?('.stylelintrc.json') ? '' : "--config #{RailsQualityAssurance.stylelint_config_path}"
        sh "npx --no-install stylelint #{config} \"**/*.css\""
      end
    end
  end

  desc 'Run frontend linters (Biome + Stylelint)'
  task frontend: %w[qa:lint:biome qa:lint:stylelint]

  desc 'Run all CI checks'
  task ci: %w[qa:lint qa:frontend spec:parallel]
end

namespace :lint do
  desc 'Alias for qa:lint'
  task all: 'qa:lint'

  desc 'Run BiomeJS linter'
  task biome: 'qa:lint:biome'

  desc 'Run Stylelint on CSS'
  task stylelint: 'qa:lint:stylelint'
end

task lint: 'qa:lint'

namespace :spec do
  desc 'Run specs in parallel with system specs isolated'
  task parallel: :environment do
    ENV['PARALLEL_TEST_FIRST_IS_1'] ||= 'true'
    parallel_tasks = ENV.fetch('PARALLEL_TEST_PROCESSORS', 3).to_s
    isolate_tasks = ENV.fetch('ISOLATE_SPEC_TASKS', 1).to_s
    test_options = ENV.fetch('PARALLEL_SPEC_OPTIONS', nil)
    raise ArgumentError, 'PARALLEL_TEST_PROCESSORS must be a positive integer' if parallel_tasks.to_i <= 0

    options = "--isolate --single spec/system/ --isolate-n #{isolate_tasks}"
    options << " --test-options=\"#{test_options}\"" if test_options
    Rake::Task['parallel:create'].invoke(parallel_tasks)
    Rake::Task['parallel:load_schema'].invoke(parallel_tasks)
    Rake::Task['parallel:spec'].invoke(parallel_tasks, nil, nil, options)
  end
end
