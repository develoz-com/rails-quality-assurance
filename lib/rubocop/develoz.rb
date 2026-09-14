# frozen_string_literal: true

require 'rubocop'
require_relative 'develoz/version'

module RuboCop
  # Shared RuboCop configuration for Develoz projects.
  module Develoz
    class Error < StandardError; end

    # Absolute path to the packaged configuration, for inherit_gem:
    #   inherit_gem:
    #     rubocop-develoz: rubocop.yml
    def self.config_path
      File.expand_path('../../rubocop.yml', __dir__)
    end
  end
end
