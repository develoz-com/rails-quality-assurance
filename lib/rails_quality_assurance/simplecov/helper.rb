# frozen_string_literal: true

module RailsQualityAssurance
  module SimpleCovHelper
    def self.configure!
      return if ENV['NO_COVERAGE']
      return if filtered_run? && !ENV['COVERAGE']

      require 'simplecov'
      require 'simplecov-lcov'

      configure_lcov_formatter
      SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
                                                                        SimpleCov::Formatter::HTMLFormatter,
                                                                        SimpleCov::Formatter::LcovFormatter
                                                                      ])
      start_coverage
    end

    def self.filtered_run?
      return false unless defined?(RSpec)

      rspec_config = RSpec.configuration
      rspec_config.files_to_run.one? ||
        rspec_config.only_failures? ||
        (rspec_config.inclusion_filter.rules&.size&.> 0)
    end

    def self.configure_lcov_formatter
      SimpleCov::Formatter::LcovFormatter.config do |formatter|
        formatter.report_with_single_file = true
        formatter.single_report_path = 'public/coverage/lcov.info'
      end
    end

    def self.start_coverage
      SimpleCov.start 'rails' do
        ENV['SIMPLECOV_INLINE_ASSETS'] = 'true'
        coverage_dir 'public/coverage'
        enable_coverage :branch

        command_name "rspec#{ENV.fetch('TEST_ENV_NUMBER', nil)}"

        add_filter '/spec/'
        add_filter '/config/'
        add_filter '/vendor/'

        SimpleCov.minimum_coverage line: 100, branch: 100
      end
    end
  end
end
