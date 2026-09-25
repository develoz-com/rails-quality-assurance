# frozen_string_literal: true

require 'parallel'

module RailsQualityAssurance
  # Resolves the parallel spec worker layout from the environment.
  #
  # `PARALLEL_TEST_PROCESSORS` is the total worker count and defaults to the
  # number of available CPUs. `ISOLATE_SPEC_TASKS` carves that many workers out
  # of the total for `spec/system/`; `0` disables isolation and system specs run
  # as ordinary specs.
  class ParallelSpecConfig
    ISOLATE_PATTERN = 'spec/system/'
    DEFAULT_ISOLATE_PROCESSORS = 1

    attr_reader :processors, :isolate_processors

    def self.from_env(env = ENV)
      processors = env.fetch('PARALLEL_TEST_PROCESSORS', Parallel.processor_count).to_i
      isolate = env.fetch('ISOLATE_SPEC_TASKS', default_isolate_processors(processors))

      new(processors:, isolate_processors: isolate)
    end

    # A single CPU cannot spare a worker for isolation.
    def self.default_isolate_processors(processors)
      processors > 1 ? DEFAULT_ISOLATE_PROCESSORS : 0
    end

    def initialize(processors:, isolate_processors:)
      @processors = Integer(processors)
      @isolate_processors = Integer(isolate_processors)

      validate
    end

    def isolate?
      isolate_processors.positive?
    end

    def parallel_options
      return '' unless isolate?

      "--isolate --single #{ISOLATE_PATTERN} --isolate-n #{isolate_processors}"
    end

    private

    def validate
      raise ArgumentError, 'PARALLEL_TEST_PROCESSORS must be a positive integer' if processors <= 0
      raise ArgumentError, 'ISOLATE_SPEC_TASKS must be zero or greater' if isolate_processors.negative?

      return if isolate_processors < processors

      raise ArgumentError, 'ISOLATE_SPEC_TASKS must be less than PARALLEL_TEST_PROCESSORS'
    end
  end
end
