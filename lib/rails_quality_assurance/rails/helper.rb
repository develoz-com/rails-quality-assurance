# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'rails_quality_assurance/playwright/helper'
require 'uri'

module RailsQualityAssurance
  # Applies the Rails-specific RSpec configuration shared by every Develoz app.
  #
  # Loaded from spec/rails_helper.rb, after the Rails environment boots:
  #
  #   # spec/rails_helper.rb
  #   require 'spec_helper'
  #   require_relative '../config/environment'
  #   require 'rails_quality_assurance/rails_helper'
  module RailsHelper
    def self.configure!
      return unless defined?(RSpec)

      verify_schema!
      RailsQualityAssurance::PlaywrightHelper.configure!
      RSpec.configure do |config|
        configure_fixtures(config)
        configure_includes(config)
        configure_network(config)
        configure_locale(config)
        configure_forgery_protection(config)
      end
    end

    def self.verify_schema!
      return unless defined?(ActiveRecord::Migration)

      ActiveRecord::Migration.maintain_test_schema!
    rescue ActiveRecord::PendingMigrationError => e
      Kernel.abort(e.to_s.strip)
    end

    def self.configure_fixtures(config)
      return unless rspec_rails?

      config.fixture_paths = [fixtures_path].compact if fixtures_path
      config.use_transactional_fixtures = true
      config.infer_spec_type_from_file_location!
      config.filter_rails_from_backtrace!
    end

    def self.fixtures_path
      return nil unless defined?(Rails)

      Rails.root.join('spec/fixtures')
    rescue NoMethodError
      nil
    end

    def self.rspec_rails?
      defined?(RSpec::Rails)
    end

    def self.configure_includes(config)
      config.include FactoryBot::Syntax::Methods if defined?(FactoryBot)
      config.include ActiveSupport::Testing::TimeHelpers if defined?(ActiveSupport::Testing::TimeHelpers)
    end

    def self.configure_network(config)
      return unless defined?(WebMock)

      allowed = localhost_hosts
      config.before { WebMock.disable_net_connect!(allow: allowed) }
    end

    # Hosts the suite may reach without stubbing: the Playwright server when
    # system specs run remotely, plus loopback.
    def self.localhost_hosts
      [playwright_host, 'localhost', '0.0.0.0', '127.0.0.1'].compact.uniq.freeze
    end

    def self.playwright_host
      url = ENV.fetch('PLAYWRIGHT_URL', nil)
      return nil if url.blank?

      URI.parse(url).host
    rescue URI::InvalidURIError
      nil
    end

    def self.configure_locale(config)
      config.before { I18n.locale = :en } if defined?(I18n)
      config.after { Faker::UniqueGenerator.clear } if defined?(Faker)
    end

    def self.configure_forgery_protection(config)
      return unless defined?(ActionController::Base)

      config.around(:each, type: :system) do |example|
        ActionController::Base.allow_forgery_protection = true
        example.run
      ensure
        ActionController::Base.allow_forgery_protection = false
      end
    end
  end
end
