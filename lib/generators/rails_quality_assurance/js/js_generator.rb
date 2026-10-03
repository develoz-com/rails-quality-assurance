# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/base'
require 'json'

module RailsQualityAssurance
  module Generators
    # Adds the JS quality-assurance CLI to a host app's package.json so the
    # frontend gates use an installed copy instead of falling back to npx.
    class JsGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Adds @develoz/quality-assurance to package.json for the frontend gates'

      def add_dev_dependency
        package = read_package
        dependencies = package['devDependencies'] ||= {}
        dependencies['@develoz/quality-assurance'] = '~0.3.0'
        write_package(package)
        say_status :updated, 'package.json', :green
      end

      def print_next_steps
        say 'Install dependencies with your package manager, then run bin/rails qa:frontend.', :green
      end

      private

      def package_path
        File.join(destination_root, 'package.json')
      end

      def read_package
        return { 'name' => File.basename(destination_root), 'private' => true } unless File.exist?(package_path)

        JSON.parse(File.read(package_path))
      end

      def write_package(package)
        File.write(package_path, "#{JSON.pretty_generate(package)}\n")
      end
    end
  end
end
