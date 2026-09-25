# frozen_string_literal: true

require 'rails_quality_assurance'
require 'fileutils'
require 'tmpdir'

RSpec.describe RailsQualityAssurance::RunLock do
  let(:dir) { Dir.mktmpdir }
  let(:path) { File.join(dir, 'qa', 'spec_parallel.lock') }

  after { FileUtils.remove_entry(dir) }

  describe '.guard' do
    it 'runs the block while holding the lock and releases it afterwards' do
      ran = false
      described_class.guard(path, command: 'spec:parallel') { ran = true }

      expect(ran).to be(true)
      expect { described_class.guard(path) { nil } }.not_to raise_error
    end

    it 'creates the lock directory when it is missing' do
      expect(File).not_to exist(File.dirname(path))

      described_class.guard(path) { nil }

      expect(File).to exist(path)
    end

    it 'releases the lock when the block raises' do
      expect { described_class.guard(path) { raise 'boom' } }.to raise_error('boom')
      expect { described_class.guard(path) { nil } }.not_to raise_error
    end

    it 'refuses to start a second run while the lock is held' do
      described_class.guard(path, command: 'spec:parallel') do
        expect { described_class.guard(path) { nil } }
          .to raise_error(described_class::Busy, /spec:parallel/)
      end
    end

    it 'reports the holder pid and elapsed time when busy' do
      described_class.guard(path, command: 'spec:parallel') do
        expect { described_class.guard(path) { nil } }
          .to raise_error(described_class::Busy, /pid #{Process.pid}, started \d+s ago/)
      end
    end

    it 'falls back to a generic message when holder metadata is unreadable' do
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, 'not json')

      File.open(path, File::RDWR) do |holder|
        holder.flock(File::LOCK_EX | File::LOCK_NB)

        expect { described_class.guard(path) { nil } }
          .to raise_error(described_class::Busy, /wait for it to finish/i)
      end
    end
  end

  describe '#acquire' do
    it 'records the holder metadata' do
      lock = described_class.new(path)
      lock.acquire('spec:parallel')

      expect(File.read(path)).to include('"command":"spec:parallel"')

      lock.release
    end

    it 'marks the descriptor inheritable so spawned workers keep the lock' do
      lock = described_class.new(path)
      lock.acquire

      expect(lock.instance_variable_get(:@file).close_on_exec?).to be(false)
    ensure
      lock&.release
    end
  end

  describe '#release' do
    it 'is idempotent' do
      lock = described_class.new(path)
      lock.acquire
      lock.release

      expect { lock.release }.not_to raise_error
    end
  end
end
