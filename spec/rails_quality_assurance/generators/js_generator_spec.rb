# frozen_string_literal: true

require 'rails_quality_assurance'
require 'generators/rails_quality_assurance/js/js_generator'
require 'json'
require 'tmpdir'

RSpec.describe RailsQualityAssurance::Generators::JsGenerator do
  it 'creates a package.json with the CLI devDependency' do
    Dir.mktmpdir do |dir|
      described_class.start([], destination_root: dir)

      package = JSON.parse(File.read(File.join(dir, 'package.json')))

      expect(package.dig('devDependencies', '@develoz/quality-assurance')).to eq('~0.3.0')
    end
  end

  it 'merges into an existing package.json without dropping dependencies' do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'package.json'),
                 JSON.generate({ 'name' => 'app', 'devDependencies' => { 'stylelint' => '^17.0.0' } }))

      described_class.start([], destination_root: dir)

      package = JSON.parse(File.read(File.join(dir, 'package.json')))

      expect(package.dig('devDependencies', '@develoz/quality-assurance')).to eq('~0.3.0')
      expect(package.dig('devDependencies', 'stylelint')).to eq('^17.0.0')
    end
  end
end
