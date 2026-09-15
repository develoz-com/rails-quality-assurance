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
    File.join(root, 'config/biome-default.json')
  end

  def self.stylelint_config_path
    File.join(root, 'config/stylelint-default.json')
  end

  def self.importmap_audit_command
    return nil unless File.exist?('config/importmap.rb')
    return 'bin/importmap audit' if File.exist?('bin/importmap')

    'bundle exec ruby -e \'require "importmap-rails"; require "importmap/map"; ' \
      'ARGV.replace(["audit"]); require "importmap/commands"\''
  end
end

require 'rails_quality_assurance/railtie'
