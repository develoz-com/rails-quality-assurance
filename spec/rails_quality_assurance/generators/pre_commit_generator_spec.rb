# frozen_string_literal: true

require 'rails_quality_assurance'
require 'generators/rails_quality_assurance/pre_commit/pre_commit_generator'
require 'fileutils'
require 'tmpdir'

RSpec.describe RailsQualityAssurance::Generators::PreCommitGenerator do
  let(:dir) { Dir.mktmpdir }
  let(:project_hook) { File.join(dir, '.githooks/pre-commit') }
  let(:git_hook) { File.join(dir, '.git/hooks/pre-commit') }

  before { system('git', '-C', dir, 'init', '--quiet') }
  after { FileUtils.remove_entry(dir) }

  def hooks_path
    `git -C #{dir} config --local core.hooksPath`.strip
  end

  def touch_in_project(relative_path)
    path = File.join(dir, relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, '')
  end

  it 'generates a tracked, executable hook with the checks' do
    described_class.start([], destination_root: dir)

    expect(File.exist?(project_hook)).to be(true)
    expect(File.executable?(project_hook)).to be(true)
    expect(File.read(project_hook)).to include('bundle exec rubocop')
  end

  it 'uses bin/rails for Reek in an app' do
    touch_in_project('bin/rails')

    described_class.start([], destination_root: dir)

    expect(File.read(project_hook)).to include('bin/rails qa:reek')
  end

  it 'uses the dummy Rakefile for Reek in an engine' do
    touch_in_project('spec/dummy/Rakefile')

    described_class.start([], destination_root: dir)

    expect(File.read(project_hook)).to include('bundle exec rake -f spec/dummy/Rakefile qa:reek')
  end

  it 'skips Reek when neither an app nor a dummy nor a config exists' do
    described_class.start([], destination_root: dir)

    expect(File.read(project_hook)).not_to include('qa:reek')
  end

  it 'prefixes every check with the runner when one is given' do
    touch_in_project('bin/rails')

    described_class.start(['--runner', 'bin/run'], destination_root: dir)

    content = File.read(project_hook)
    expect(content).to include('bin/run bundle exec rubocop')
    expect(content).to include('bin/run bin/rails qa:reek')
    expect(content).to include('bin/run bundle exec rspec --fail-fast')
    expect(content).not_to include('bin/run bin/run')
  end

  it 'installs a launcher without touching core.hooksPath' do
    described_class.start([], destination_root: dir)

    expect(File.exist?(git_hook)).to be(true)
    expect(File.executable?(git_hook)).to be(true)
    expect(File.read(git_hook)).to include('.githooks/pre-commit')
    expect(hooks_path).to eq('')
  end

  it 'aborts when core.hooksPath points elsewhere' do
    system('git', '-C', dir, 'config', '--local', 'core.hooksPath', '.husky')

    expect { described_class.start([], destination_root: dir) }
      .to output(/core\.hooksPath is set/).to_stdout.or(output(/core\.hooksPath is set/).to_stderr)

    expect(File.exist?(project_hook)).to be(false)
    expect(File.exist?(git_hook)).to be(false)
  end

  it 'keeps an existing shared hook instead of replacing it' do
    shared = File.join(dir, 'shared-pre-commit')
    File.write(shared, "#!/bin/sh\nexit 0\n")
    FileUtils.mkdir_p(File.dirname(git_hook))
    File.symlink(shared, git_hook)

    described_class.start([], destination_root: dir)

    expect(File.symlink?(git_hook)).to be(true)
    expect(File.readlink(git_hook)).to eq(shared)
    expect(File.exist?(project_hook)).to be(true)
  end
end
