# frozen_string_literal: true

module RailsQualityAssurance
  # Resolves the SimpleCov minimum coverage and maximum coverage drop
  # thresholds from the environment and any pre-existing SimpleCov
  # configuration (typically declared in `.simplecov`).
  #
  # Precedence, highest first:
  # 1. Environment variables
  # 2. Existing SimpleCov configuration
  # 3. Gem defaults: 100% line and branch minimum, no coverage drop
  class SimpleCovConfig
    MINIMUM_ENV_KEYS = {
      line: 'MINIMUM_LINE_COVERAGE',
      branch: 'MINIMUM_BRANCH_COVERAGE'
    }.freeze
    DROP_ENV_KEYS = {
      line: 'MAXIMUM_COVERAGE_DROP',
      branch: 'MAXIMUM_COVERAGE_DROP_BRANCH'
    }.freeze
    DEFAULT_MINIMUM = { line: 100, branch: 100 }.freeze

    def self.from_env(env = ENV, existing_minimum: {}, existing_drop: {})
      new(env:, existing_minimum:, existing_drop:)
    end

    attr_reader :minimum_coverage, :maximum_coverage_drop

    def initialize(existing_minimum: {}, existing_drop: {}, env: ENV)
      @env = env
      @minimum_coverage = resolve_minimum(existing_minimum)
      @maximum_coverage_drop = resolve_drop(existing_drop)
    end

    private

    attr_reader :env

    def resolve_minimum(existing)
      MINIMUM_ENV_KEYS.each_with_object(existing.dup) do |(criterion, key), minimum|
        fallback = existing.fetch(criterion, DEFAULT_MINIMUM.fetch(criterion))
        minimum[criterion] = parse_threshold(env[key], name: key, fallback:)
      end
    end

    def resolve_drop(existing)
      DROP_ENV_KEYS.each_with_object(existing.dup) do |(criterion, key), drop|
        next unless env.key?(key)

        value = parse_threshold(env[key], name: key, fallback: nil)
        drop[criterion] = value if value
      end
    end

    def parse_threshold(value, name:, fallback:)
      return fallback if value.to_s.strip.empty?

      number = coerce_number(value, name:)
      integer = number.to_i
      number == integer ? integer : number
    end

    def coerce_number(value, name:)
      number = Float(value)
      return number if number.between?(0, 100)

      raise ArgumentError, "#{name} must be between 0 and 100 (got #{value})"
    rescue ArgumentError, TypeError
      raise ArgumentError, "#{name} must be a number between 0 and 100 (got #{value.inspect})"
    end
  end
end
