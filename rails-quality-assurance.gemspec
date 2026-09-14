# frozen_string_literal: true

require_relative 'lib/rails_quality_assurance/version'

Gem::Specification.new do |spec|
  spec.name = 'rails-quality-assurance'
  spec.version = RailsQualityAssurance::VERSION
  spec.authors = ['Mauricio Zaffari']
  spec.email = ['mauricio@develoz.com']

  spec.summary = 'Opinionated quality assurance kit for Rails applications.'
  spec.description = 'Unified QA kit for Rails apps: testing, linters, security audits, parallel execution, and CI.'
  spec.homepage = 'https://github.com/develoz-com/rails-quality-assurance'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 4.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['{config,lib}/**/*', 'CHANGELOG.md', 'LICENSE.txt', 'README.md', 'rubocop.yml']
  spec.require_paths = ['lib']

  # RuboCop & plugins
  spec.add_dependency 'rubocop', '~> 1.85.0'
  spec.add_dependency 'rubocop-capybara', '~> 2.22.0'
  spec.add_dependency 'rubocop-factory_bot', '~> 2.28.0'
  spec.add_dependency 'rubocop-migration', '~> 0.7.1'
  spec.add_dependency 'rubocop-performance', '~> 1.26.0'
  spec.add_dependency 'rubocop-rails', '~> 2.34.0'
  spec.add_dependency 'rubocop-rspec', '~> 3.9.0'
  spec.add_dependency 'rubocop-rspec_rails', '~> 2.32.0'
  spec.add_dependency 'rubocop-rubycw', '~> 0.2.0'

  # Static analysis & Security
  spec.add_dependency 'brakeman', '>= 7.0'
  spec.add_dependency 'bundler-audit', '>= 0.9'
  spec.add_dependency 'flay', '>= 2.14'
  spec.add_dependency 'reek', '>= 6.3'

  # Testing & Coverage
  spec.add_dependency 'parallel_tests', '>= 5.0'
  spec.add_dependency 'rspec-rails', '>= 7.0'
  spec.add_dependency 'simplecov', '~> 1.3.0'
  spec.add_dependency 'simplecov-lcov', '>= 0.9'

  # Browser & System testing
  spec.add_dependency 'capybara', '>= 3.40'
  spec.add_dependency 'capybara-playwright-driver', '>= 0.5.0'
  spec.add_dependency 'playwright-ruby-client', '>= 1.50.0'

  # Optional Rails integration
  spec.add_dependency 'railties', '>= 7.0'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.13'
end
