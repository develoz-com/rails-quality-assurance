# frozen_string_literal: true

require 'rails_quality_assurance'

RSpec.describe RailsQualityAssurance::ParallelSpecConfig do
  describe '.from_env' do
    it 'defaults the worker count to the CPU count' do
      allow(Parallel).to receive(:processor_count).and_return(6)

      expect(described_class.from_env({}).processors).to eq(6)
    end

    it 'reserves one isolate worker by default, leaving the rest for tests' do
      allow(Parallel).to receive(:processor_count).and_return(6)

      config = described_class.from_env({})

      expect(config.isolate_processors).to eq(1)
      expect(config.parallel_options).to eq('--isolate --single spec/system/ --isolate-n 1')
    end

    it 'skips isolation on a single-CPU machine' do
      allow(Parallel).to receive(:processor_count).and_return(1)

      config = described_class.from_env({})

      expect(config).not_to be_isolate
      expect(config.parallel_options).to eq('')
    end

    it 'reads PARALLEL_TEST_PROCESSORS' do
      expect(described_class.from_env('PARALLEL_TEST_PROCESSORS' => '8').processors).to eq(8)
    end

    it 'reads ISOLATE_SPEC_TASKS' do
      config = described_class.from_env('PARALLEL_TEST_PROCESSORS' => '8', 'ISOLATE_SPEC_TASKS' => '3')

      expect(config.isolate_processors).to eq(3)
      expect(config.parallel_options).to eq('--isolate --single spec/system/ --isolate-n 3')
    end

    it 'disables isolation when ISOLATE_SPEC_TASKS is 0' do
      config = described_class.from_env('PARALLEL_TEST_PROCESSORS' => '8', 'ISOLATE_SPEC_TASKS' => '0')

      expect(config).not_to be_isolate
      expect(config.parallel_options).to eq('')
    end
  end

  describe 'validation' do
    it 'rejects a non-positive worker count' do
      expect { described_class.new(processors: 0, isolate_processors: 0) }
        .to raise_error(ArgumentError, /PARALLEL_TEST_PROCESSORS/)
    end

    it 'rejects a negative isolate count' do
      expect { described_class.new(processors: 4, isolate_processors: -1) }
        .to raise_error(ArgumentError, /ISOLATE_SPEC_TASKS/)
    end

    it 'rejects isolating every worker' do
      expect { described_class.new(processors: 2, isolate_processors: 2) }
        .to raise_error(ArgumentError, /less than/)
    end
  end
end
