# frozen_string_literal: true

require 'rails_quality_assurance/version'
require 'rails_quality_assurance/ci'

module RailsQualityAssurance
  class Error < StandardError; end

  def self.root
    File.expand_path('..', __dir__)
  end

  def self.rubocop_config_path
    File.join(root, 'rubocop.yml')
  end

  def self.reek_config_path
    File.join(root, 'config/reek.yml')
  end

  def self.biome_config_path
    File.join(root, 'config/biome.json')
  end

  def self.stylelint_config_path
    File.join(root, 'config/.stylelintrc.json')
  end
end

require 'rails_quality_assurance/railtie' if defined?(Rails::Railtie)
