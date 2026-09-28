# frozen_string_literal: true

require 'rails_quality_assurance/simplecov_config'

module RailsQualityAssurance
  # Configures SimpleCov with parallel_tests support.
  #
  # SimpleCov 1.2+ infers `finalize_merge false` for parallel workers that
  # merge into an explicit coverage destination (assumed external `collate`),
  # which silently skips threshold enforcement. We do a plain parallel run, so
  # we set it true: the first worker waits for its siblings, merges, formats,
  # enforces thresholds, and writes `.last_run.json` exactly once.
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
      return false if parallel_run?

      rspec_config = RSpec.configuration
      rspec_config.files_to_run.one? ||
        rspec_config.only_failures? ||
        (rspec_config.inclusion_filter.rules&.size&.> 0)
    end

    def self.parallel_run?
      ENV.key?('TEST_ENV_NUMBER') || ENV.key?('PARALLEL_TEST_GROUPS') || ENV.key?('PARALLEL_PID_FILE')
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

        skip '/spec/'
        skip '/config/'
        skip '/vendor/'

        finalize_merge true
      end

      apply_thresholds
    end

    # Applied after `SimpleCov.start` so `.simplecov` values supply the
    # fallbacks instead of being overwritten by the gem defaults.
    def self.apply_thresholds(env: ENV)
      config = SimpleCovConfig.from_env(
        env,
        existing_minimum: SimpleCov.minimum_coverage,
        existing_drop: SimpleCov.maximum_coverage_drop
      )

      SimpleCov.minimum_coverage(config.minimum_coverage)
      SimpleCov.maximum_coverage_drop(config.maximum_coverage_drop)
    end
  end
end
