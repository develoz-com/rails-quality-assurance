# frozen_string_literal: true

require 'rubocop/develoz'

RSpec.describe RuboCop::Develoz do
  describe 'VERSION' do
    it 'is a semantic version string' do
      expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end

  describe '.config_path' do
    it 'resolves to the packaged rubocop.yml' do
      expect(described_class.config_path).to end_with('rubocop-develoz/rubocop.yml')
    end

    it 'exists on disk' do
      expect(File.exist?(described_class.config_path)).to be(true)
    end
  end

  describe 'packaged rubocop.yml' do
    let(:raw) { YAML.unsafe_load_file(described_class.config_path) }
    let(:config) { RuboCop::ConfigLoader.load_file(described_class.config_path) }

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

    it 'targets the shared Ruby version' do
      expect(config.dig('AllCops', 'TargetRubyVersion')).to eq(3.4)
    end

    it 'keeps shared metrics and style decisions' do
      expect(config.dig('Metrics/AbcSize', 'Max')).to eq(35)
      expect(config.dig('Metrics/MethodLength', 'Max')).to eq(30)
      expect(config.dig('Layout/LineLength', 'Max')).to eq(120)
      expect(config.dig('Style/HashSyntax', 'EnforcedShorthandSyntax')).to eq('always')
      expect(config.dig('Style/Documentation', 'Enabled')).to be(false)
    end

    it 'uses current cop namespaces' do
      cop_names = config.keys - %w[inherit_mode plugins AllCops]
      expect(cop_names).to all(match(%r{\A[A-Z][A-Za-z]+(/[A-Z][A-Za-z0-9]+)+\z}))
    end
  end
end
