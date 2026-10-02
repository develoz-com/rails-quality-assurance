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

        @reek_command = reek_command
        template 'pre_commit.erb', '.githooks/pre-commit'
        chmod '.githooks/pre-commit', 0o755
        install_launcher
      end

      private

      # Reek runs through the gem's Rake task. Apps expose it via `bin/rails`;
      # gems and engines expose it through their dummy app's Rakefile. A plain
      # gem with its own `.reek.yml` falls back to bare Reek; otherwise the
      # check is skipped rather than failing on a missing task.
      def reek_command
        return 'bin/rails qa:reek' if exist?('bin/rails')
        return 'bundle exec rake -f spec/dummy/Rakefile qa:reek' if exist?('spec/dummy/Rakefile')
        return 'bundle exec reek' if exist?('.reek.yml')

        nil
      end

      def exist?(path)
        File.exist?(File.join(destination_root, path))
      end

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
