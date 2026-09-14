# frozen_string_literal: true

require 'rails_quality_assurance'
require 'generators/rails_quality_assurance/ci/ci_generator'
require 'fileutils'
require 'tmpdir'

RSpec.describe RailsQualityAssurance::Generators::CiGenerator do
  it 'generates bin/ci and config/ci.rb' do
    Dir.mktmpdir do |dir|
      described_class.start([], destination_root: dir)

      bin_ci = File.join(dir, 'bin/ci')
      config_ci = File.join(dir, 'config/ci.rb')

      expect(File.exist?(bin_ci)).to be(true)
      expect(File.executable?(bin_ci)).to be(true)
      expect(File.read(bin_ci)).to include("require 'rails_quality_assurance/ci_runner'")

      expect(File.exist?(config_ci)).to be(true)
      expect(File.read(config_ci)).to include('CI.run do')
    end
  end
end
