# frozen_string_literal: true

require 'rails_quality_assurance'
require 'rubocop'
require 'yaml'

RSpec.describe RailsQualityAssurance do
  describe 'VERSION' do
    it 'is a semantic version string' do
      expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end

  describe 'paths' do
    it 'locates the gem root' do
      expect(File.directory?(described_class.root)).to be(true)
    end

    it 'locates rubocop.yml' do
      expect(File.exist?(described_class.rubocop_config_path)).to be(true)
    end

    it 'locates reek.yml' do
      expect(File.exist?(described_class.reek_config_path)).to be(true)
    end

    it 'locates biome.json' do
      expect(File.exist?(described_class.biome_config_path)).to be(true)
    end

    it 'locates .stylelintrc.json' do
      expect(File.exist?(described_class.stylelint_config_path)).to be(true)
    end
  end

  describe 'packaged rubocop.yml' do
    let(:raw) { YAML.unsafe_load_file(described_class.rubocop_config_path) }
    let(:config) { RuboCop::ConfigLoader.load_file(described_class.rubocop_config_path) }

    it 'declares all required plugins' do
      expect(raw['plugins']).to contain_exactly(
        'rubocop-performance', 'rubocop-rspec', 'rubocop-rspec_rails',
        'rubocop-capybara', 'rubocop-factory_bot', 'rubocop-rubycw',
        'rubocop-migration', 'rubocop-rails'
      )
    end

    it 'merges Exclude so projects can add their own' do
      expect(config.dig('inherit_mode', 'merge')).to eq(['Exclude'])
    end

    it 'targets Ruby 4.0' do
      expect(config.dig('AllCops', 'TargetRubyVersion')).to eq(4.0)
    end

    it 'keeps metric thresholds' do
      expect(config.dig('Metrics/AbcSize', 'Max')).to eq(35)
      expect(config.dig('Metrics/MethodLength', 'Max')).to eq(30)
      expect(config.dig('Metrics/ClassLength', 'Max')).to eq(150)
      expect(config.dig('Layout/LineLength', 'Max')).to eq(120)
    end

    it 'keeps style decisions' do
      expect(config.dig('Style/HashSyntax', 'EnforcedShorthandSyntax')).to eq('always')
      expect(config.dig('Style/Documentation', 'Enabled')).to be(false)
    end
  end
end
