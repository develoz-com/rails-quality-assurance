# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/base'

module RailsQualityAssurance
  module Generators
    # Installs a project-owned pre-commit hook
    class PreCommitGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Installs a pre-commit hook for RuboCop, Reek, and RSpec'

      def install_hook
        guard_hooks_path

        template 'pre_commit.erb', '.githooks/pre-commit'
        chmod '.githooks/pre-commit', 0o755
        install_launcher
      end

      private

      # Git ignores `.git/hooks` entirely when `core.hooksPath` is set, so the
      # launcher would never run. Fail loudly instead of installing a no-op.
      def guard_hooks_path
        return if hooks_path.empty?

        raise Thor::Error, "core.hooksPath is set to #{hooks_path.inspect}; " \
                           'this hook installs into .git/hooks and cannot be activated'
      end

      # Deploy `.git/hooks/pre-commit` only when nothing is there yet. A shared
      # hook manager already owns that path and can chain to
      # `.githooks/pre-commit`, so overwriting it would disable its other hooks,
      # such as `prepare-commit-msg`.
      def install_launcher
        path = File.join(git_dir, 'hooks', 'pre-commit')

        if File.exist?(path) || File.symlink?(path)
          say_status :keep, path, :yellow
        else
          copy_file 'launcher.sh', path
          chmod path, 0o755
        end
      end

      def hooks_path
        IO.popen(['git', '-C', destination_root, 'config', 'core.hooksPath'],
                 err: File::NULL, &:read).strip
      end

      def git_dir
        IO.popen(['git', '-C', destination_root, 'rev-parse', '--absolute-git-dir'],
                 err: File::NULL, &:read).strip
      end
    end
  end
end
