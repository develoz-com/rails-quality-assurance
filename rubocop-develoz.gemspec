# frozen_string_literal: true

require_relative 'lib/rubocop/develoz/version'

Gem::Specification.new do |spec|
  spec.name = 'rubocop-develoz'
  spec.version = RuboCop::Develoz::VERSION
  spec.authors = ['Mauricio Zaffari']
  spec.email = ['mauriciozaffari@gmail.com']

  spec.summary = 'Develoz Ruby styling for Rails and gems.'
  spec.description = 'Shared RuboCop configuration for Develoz projects: Rails apps and Ruby gems.'
  spec.homepage = 'https://github.com/develoz-com/rubocop-develoz'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |file|
      (file == gemspec) ||
        file.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ docs/ templates/])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |file| File.basename(file) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rubocop', '~> 1.85.0'
  spec.add_dependency 'rubocop-capybara', '~> 2.22.0'
  spec.add_dependency 'rubocop-factory_bot', '~> 2.28.0'
  spec.add_dependency 'rubocop-migration', '~> 0.7.1'
  spec.add_dependency 'rubocop-performance', '~> 1.26.0'
  spec.add_dependency 'rubocop-rails', '~> 2.34.0'
  spec.add_dependency 'rubocop-rspec', '~> 3.9.0'
  spec.add_dependency 'rubocop-rspec_rails', '~> 2.32.0'
  spec.add_dependency 'rubocop-rubycw', '~> 0.2.0'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.13'
end
