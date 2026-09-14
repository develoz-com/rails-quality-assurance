# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/base'

module RailsQualityAssurance
  module Generators
    # Generates bin/ci and config/ci.rb for host-level CI execution
    class CiGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Installs bin/ci and config/ci.rb for Rails Continuous Integration'

      def copy_ci_files
        template 'bin_ci.erb', 'bin/ci'
        chmod 'bin/ci', 0o755
        template 'config_ci.rb.erb', 'config/ci.rb'
      end
    end
  end
end
