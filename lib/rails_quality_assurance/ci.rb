# frozen_string_literal: true

require 'English'

module RailsQualityAssurance
  # Continuous Integration test and lint execution harness
  class CI
    # Represents a single verification step in the pipeline
    class Step
      attr_reader :name, :command

      def initialize(name, command)
        @name = name
        @command = command
      end

      def run
        banner("Running: #{name}")

        system(command)
        exit_code = $CHILD_STATUS&.exitstatus || 1

        if exit_code.zero?
          puts "✓ #{name} passed"
        else
          puts "✗ #{name} failed (exit code: #{exit_code})"
          Kernel.exit(exit_code)
        end
      end
    end

    def self.run(&)
      runner = new
      runner.instance_eval(&) if block_given?
      runner.execute
    end

    def initialize
      @steps = []
    end

    def step(name, command = nil, &block)
      @steps << [name, command || block]
    end

    def execute
      banner('Rails Quality Assurance Pipeline')

      @steps.each do |name, action|
        if action.is_a?(Proc)
          banner("Running: #{name}")
          action.call
        else
          Step.new(name, action).run
        end
      end

      banner('✓ All Quality Assurance checks passed')
    end

    private

    def banner(text)
      separator = '=' * 60
      puts "\n#{separator}"
      puts text
      puts separator
    end
  end
end
