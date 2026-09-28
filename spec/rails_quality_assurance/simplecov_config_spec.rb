# frozen_string_literal: true

require 'rails_quality_assurance'

RSpec.describe RailsQualityAssurance::SimpleCovConfig do
  subject(:config) { described_class.from_env(env, **existing) }

  let(:env) { {} }
  let(:existing) { {} }

  describe '.from_env' do
    context 'without configuration' do
      it 'defaults to 100% line and branch minimum coverage' do
        expect(config.minimum_coverage).to eq(line: 100, branch: 100)
      end

      it 'leaves maximum coverage drop unset' do
        expect(config.maximum_coverage_drop).to eq({})
      end
    end

    context 'with existing SimpleCov configuration' do
      let(:existing) { { existing_minimum: { line: 80, branch: 70 }, existing_drop: { line: 2 } } }

      it 'keeps the configured minimum coverage' do
        expect(config.minimum_coverage).to eq(line: 80, branch: 70)
      end

      it 'keeps the configured maximum coverage drop' do
        expect(config.maximum_coverage_drop).to eq(line: 2)
      end

      it 'defaults the criterion the project did not set' do
        expect(described_class.from_env({}, existing_minimum: { line: 80 }).minimum_coverage)
          .to eq(line: 80, branch: 100)
      end

      it 'keeps criteria the gem does not manage' do
        expect(described_class.from_env({}, existing_minimum: { line: 80, method: 90 }).minimum_coverage)
          .to eq(line: 80, branch: 100, method: 90)
      end
    end

    context 'with environment overrides' do
      let(:env) do
        {
          'MINIMUM_LINE_COVERAGE' => '95',
          'MINIMUM_BRANCH_COVERAGE' => '90.5',
          'MAXIMUM_COVERAGE_DROP' => '5',
          'MAXIMUM_COVERAGE_DROP_BRANCH' => '3'
        }
      end
      let(:existing) { { existing_minimum: { line: 80, branch: 70 }, existing_drop: { line: 2, branch: 1 } } }

      it 'overrides existing minimum coverage' do
        expect(config.minimum_coverage).to eq(line: 95, branch: 90.5)
      end

      it 'overrides existing maximum coverage drop per criterion' do
        expect(config.maximum_coverage_drop).to eq(line: 5, branch: 3)
      end

      it 'overrides only the criterion whose variable is set' do
        env = { 'MINIMUM_LINE_COVERAGE' => '95' }

        expect(described_class.from_env(env, existing_minimum: { line: 80, branch: 70 }).minimum_coverage)
          .to eq(line: 95, branch: 70)
      end

      it 'treats a blank value as unset' do
        env = { 'MINIMUM_LINE_COVERAGE' => '  ' }

        expect(described_class.from_env(env, existing_minimum: { line: 80 }).minimum_coverage)
          .to eq(line: 80, branch: 100)
      end

      it 'coerces whole numbers to integers and keeps decimals as floats' do
        env = { 'MINIMUM_LINE_COVERAGE' => '90', 'MINIMUM_BRANCH_COVERAGE' => '99.9' }

        expect(described_class.from_env(env).minimum_coverage).to eq(line: 90, branch: 99.9)
      end

      it 'accepts zero to disable a threshold' do
        expect(described_class.from_env({ 'MINIMUM_BRANCH_COVERAGE' => '0' }).minimum_coverage)
          .to eq(line: 100, branch: 0)
      end
    end

    describe 'validation' do
      it 'rejects a non-numeric value' do
        expect { described_class.from_env({ 'MINIMUM_LINE_COVERAGE' => 'abc' }) }
          .to raise_error(ArgumentError, /MINIMUM_LINE_COVERAGE/)
      end

      it 'rejects a value above 100' do
        expect { described_class.from_env({ 'MAXIMUM_COVERAGE_DROP' => '101' }) }
          .to raise_error(ArgumentError, /MAXIMUM_COVERAGE_DROP/)
      end

      it 'rejects a negative value' do
        expect { described_class.from_env({ 'MINIMUM_BRANCH_COVERAGE' => '-1' }) }
          .to raise_error(ArgumentError, /MINIMUM_BRANCH_COVERAGE/)
      end
    end
  end
end
