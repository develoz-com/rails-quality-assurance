# frozen_string_literal: true

require 'rails_quality_assurance/simplecov/helper'
require 'rails_quality_assurance/playwright/helper'

module RailsQualityAssurance
  module RSpecHelper
    def self.configure!
      return unless defined?(RSpec)

      RSpec.configure do |config|
        configure_expectations(config)
        configure_mocks(config)
        config.shared_context_metadata_behavior = :apply_to_host_groups
        config.order = :random
      end
    end

    def self.configure_expectations(config)
      config.expect_with :rspec do |expectations|
        expectations.include_chain_clauses_in_custom_matcher_descriptions = true
      end
    end

    def self.configure_mocks(config)
      config.mock_with :rspec do |mocks|
        mocks.verify_partial_doubles = true
      end
    end
  end
end
