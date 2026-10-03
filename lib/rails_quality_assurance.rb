# frozen_string_literal: true

require 'rails_quality_assurance/error'
require 'rails_quality_assurance/version'
require 'rails_quality_assurance/ci'
require 'rails_quality_assurance/parallel_spec_config'
require 'rails_quality_assurance/run_lock'
require 'rails_quality_assurance/simplecov_config'

module RailsQualityAssurance
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

  # Resolves the JavaScript security audit command from the lockfile in use,
  # gating on high and critical advisories. Audits production dependencies only:
  # dev tooling carries advisories that never ship, and blocking a deploy on
  # them is noise. Returns nil when the app has no lockfile.
  def self.npm_audit_command
    if File.exist?('package-lock.json')
      'npm audit --audit-level=high --omit=dev'
    elsif File.exist?('yarn.lock')
      # Yarn 1 ignores --level for its exit code and returns a severity bitmask
      # (info 1, low 2, moderate 4, high 8, critical 16), so mask high|critical.
      # --groups dependencies limits the audit to production dependencies.
      'yarn audit --groups dependencies; status=$?; [ $((status & 24)) -eq 0 ]'
    elsif File.exist?('pnpm-lock.yaml')
      'pnpm audit --audit-level high --prod'
    end
  end

  # Shared lock file that serializes parallel spec runs for the current app.
  def self.spec_lock_path
    File.join('tmp', 'qa', 'spec_parallel.lock')
  end
end

require 'rails_quality_assurance/railtie'
