# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/module/delegation'
require 'rails/railtie'

module RailsQualityAssurance
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../tasks/quality_assurance.rake', __dir__)
    end
  end
end
