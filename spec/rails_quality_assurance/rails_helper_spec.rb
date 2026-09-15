# frozen_string_literal: true

require 'rails_quality_assurance'
require 'rails_quality_assurance/rails/helper'

RSpec.describe RailsQualityAssurance::RailsHelper do
  describe '.playwright_host' do
    around do |example|
      original = ENV.fetch('PLAYWRIGHT_URL', nil)
      example.run
    ensure
      ENV['PLAYWRIGHT_URL'] = original
    end

    it 'returns the host from PLAYWRIGHT_URL' do
      ENV['PLAYWRIGHT_URL'] = 'ws://playwright:3005/ws'
      expect(described_class.playwright_host).to eq('playwright')
    end

    it 'returns nil when PLAYWRIGHT_URL is unset' do
      ENV.delete('PLAYWRIGHT_URL')
      expect(described_class.playwright_host).to be_nil
    end

    it 'returns nil when PLAYWRIGHT_URL is empty' do
      ENV['PLAYWRIGHT_URL'] = ''
      expect(described_class.playwright_host).to be_nil
    end

    it 'returns nil for a malformed URL' do
      ENV['PLAYWRIGHT_URL'] = 'http://[bad'
      expect(described_class.playwright_host).to be_nil
    end
  end

  describe '.localhost_hosts' do
    around do |example|
      original = ENV.fetch('PLAYWRIGHT_URL', nil)
      example.run
    ensure
      ENV['PLAYWRIGHT_URL'] = original
    end

    it 'always allows loopback' do
      ENV['PLAYWRIGHT_URL'] = 'ws://playwright:3005/ws'
      expect(described_class.localhost_hosts).to include('localhost', '0.0.0.0', '127.0.0.1')
    end

    it 'includes the Playwright server host when configured' do
      ENV['PLAYWRIGHT_URL'] = 'ws://playwright:3005/ws'
      expect(described_class.localhost_hosts).to include('playwright')
    end

    it 'omits nil entries' do
      ENV.delete('PLAYWRIGHT_URL')
      expect(described_class.localhost_hosts).not_to include(nil)
    end
  end

  describe '.configure!' do
    it 'registers configuration without raising' do
      expect { described_class.configure! }.not_to raise_error
    end

    it 'is idempotent' do
      described_class.configure!
      expect { described_class.configure! }.not_to raise_error
    end
  end
end
