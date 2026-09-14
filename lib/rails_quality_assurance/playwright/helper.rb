# frozen_string_literal: true

module RailsQualityAssurance
  module PlaywrightHelper
    def self.configure!
      require 'capybara'
      require 'capybara-playwright-driver'

      playwright_url = ENV.fetch('PLAYWRIGHT_URL', nil)
      capybara_port = ENV.fetch('CAPYBARA_SERVER_PORT', 3001)

      register_capybara_driver(playwright_url)
      configure_rspec(playwright_url, capybara_port) if defined?(RSpec)
    end

    def self.register_capybara_driver(playwright_url)
      Capybara.register_driver :remote_playwright do |app|
        options = {
          browser_type: :chromium,
          headless: true,
          args: ['--disable-dev-shm-usage'],
          viewport: { width: 1400, height: 1400 },
          screen: { width: 1400, height: 1400 }
        }

        if playwright_url.present?
          options[:browser_server_endpoint_url] = playwright_url
        elsif local_playwright_cli
          options[:playwright_cli_executable_path] = local_playwright_cli.to_s
        end

        Capybara::Playwright::Driver.new(app, **options)
      end
    end

    def self.local_playwright_cli
      return nil unless defined?(Rails)

      cli_path = Rails.root.join('node_modules/.bin/playwright-core')
      cli_path.executable? ? cli_path : nil
    end

    def self.configure_rspec(playwright_url, capybara_port)
      RSpec.configure do |config|
        setup_system_hooks(config, playwright_url, capybara_port)
        setup_failure_dump(config)
      end
    end

    def self.setup_system_hooks(config, playwright_url, capybara_port)
      config.before(type: :system) do
        Capybara.default_max_wait_time = 10
        driven_by :rack_test
      end

      config.before(type: :system, js: true) do
        PlaywrightHelper.apply_js_system_driver(playwright_url, capybara_port)
      end
    end

    def self.apply_js_system_driver(playwright_url, capybara_port)
      if playwright_url.present?
        Capybara.server_host = '0.0.0.0'
        base_port = capybara_port.to_i
        test_env_number = (ENV.fetch('TEST_ENV_NUMBER', nil) || '0').to_i
        Capybara.server_port = base_port + test_env_number

        hostname = Socket.gethostname
        Capybara.app_host = "http://#{hostname}:#{Capybara.server_port}"
      else
        Capybara.server_port = nil
        Capybara.app_host = nil
      end

      Capybara.current_driver = :remote_playwright
    end

    def self.setup_failure_dump(config)
      config.after(type: :system) do |example|
        next unless example.exception
        next unless defined?(Rails)

        session = Capybara.current_session
        next unless session.current_url.to_s.start_with?('http')

        save_dir = Rails.root.join('tmp/capybara')
        FileUtils.mkdir_p(save_dir)
        slug = example.full_description.parameterize.first(120)
        path = save_dir.join("failure-#{slug}-#{Process.pid}.html")
        File.write(path, session.html)
      rescue StandardError
        # Never fail the suite on diagnostic errors
      end
    end
  end
end
