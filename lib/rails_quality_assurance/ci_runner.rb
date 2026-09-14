# frozen_string_literal: true

require 'rails_quality_assurance/ci'

# Emulate ActiveSupport::ContinuousIntegration interface if needed
unless defined?(ActiveSupport::ContinuousIntegration)
  module ActiveSupport
    module ContinuousIntegration
      def self.run(&)
        RailsQualityAssurance::CI.run(&)
      end
    end
  end
end
