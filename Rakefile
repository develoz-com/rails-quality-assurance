# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc 'Run RuboCop linter'
task :rubocop do
  sh 'bundle exec rubocop'
end

desc 'Run Reek code smell detector'
task :reek do
  sh 'bundle exec reek --config .reek.yml lib'
end

desc 'Run CI checks'
task :ci do
  sh 'bin/ci'
end

task default: :spec
