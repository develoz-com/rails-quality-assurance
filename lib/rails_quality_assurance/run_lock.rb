# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'
require 'rails_quality_assurance/error'

module RailsQualityAssurance
  # Cross-process exclusive lock that serializes heavy runs such as the
  # parallel spec suite.
  #
  # The lock is held through `flock`, so the kernel releases it when the last
  # holder exits, even on SIGKILL. The holder descriptor is made inheritable so
  # workers spawned by the guarded run keep the lock alive if the coordinating
  # process dies mid-run.
  class RunLock
    # Raised when another run already holds the lock.
    class Busy < Error; end

    def self.guard(path, command: nil)
      lock = new(path)
      lock.acquire(command)

      begin
        yield
      ensure
        lock.release
      end
    end

    def initialize(path)
      @path = path
      @file = nil
    end

    # Takes the lock and records the holder, or raises Busy with the current
    # holder's details so the caller can tell what is already running.
    def acquire(command = nil)
      @file = open_file

      return record_holder(command) if try_lock

      message = busy_message
      release
      raise Busy, message
    end

    def release
      return unless @file

      @file.flock(File::LOCK_UN)
      @file.close
      @file = nil
    end

    private

    def try_lock
      @file.flock(File::LOCK_EX | File::LOCK_NB)
    rescue Errno::EWOULDBLOCK, Errno::EAGAIN
      false
    end

    def record_holder(command)
      # Spawned workers must inherit the descriptor, otherwise the lock is
      # released the moment the coordinating process dies while they still run.
      @file.close_on_exec = false
      write_metadata(command)

      self
    end

    def open_file
      FileUtils.mkdir_p(File.dirname(@path))
      File.open(@path, File::RDWR | File::CREAT, 0o644)
    end

    def write_metadata(command)
      @file.rewind
      @file.truncate(0)
      @file.write(JSON.generate('pid' => Process.pid, 'started_at' => Time.now.utc.iso8601, 'command' => command))
      @file.flush
    end

    def busy_message
      holder = metadata
      return 'Another quality assurance run is already in progress; wait for it to finish.' if holder.empty?

      "Another quality assurance run is already in progress: #{holder['command']} " \
        "(pid #{holder['pid']}, started #{elapsed(holder['started_at'])} ago). " \
        'Wait for it to finish before starting another run.'
    end

    def metadata
      @file.rewind
      JSON.parse(@file.read)
    rescue JSON::ParserError, TypeError
      {}
    end

    def elapsed(started_at)
      seconds = (Time.now.utc - Time.iso8601(started_at.to_s)).round
      return "#{seconds}s" if seconds < 60

      minutes = seconds / 60
      return "#{minutes}m#{seconds % 60}s" if minutes < 60

      "#{minutes / 60}h#{minutes % 60}m"
    rescue ArgumentError, TypeError
      'an unknown time'
    end
  end
end
