# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module ThreadsHelper

  # Ensure that any new threads which might be spawned by the block will be cleaned up
  #   to not interfere with any subsequent tests.
  def ensure_threads_exited()
    initial_threads = Thread.list
    yield
  ensure
    # Keep going until no more changes are needed to catch threads spawned in between.
    (Thread.list - initial_threads).each(&:kill) while (Thread.list - initial_threads).count.positive?
  end

  # Thread control loops usually run forever. This method can test that they were started.
  def ensure_block_keeps_running(timeout: 2.seconds, &block)
    # Stop after timeout and return true if everything was ok.
    Timeout.timeout(timeout, &block)
    raise 'Process ended unexpectedly.'
  rescue SystemExit
    # Convert SystemExit to a RuntimeError as otherwise rspec will shut down without an error.
    raise 'Process tried to shut down unexpectedly.'
  rescue Timeout::Error
    # Default case: process started fine and kept running, interrupted by timeout.
    true
  end

  def ensure_block_keeps_running_in_thread(timeout: 2.seconds, sleep_duration: 0.1.seconds, &block)
    thread = Thread.new { ensure_block_keeps_running(&block) }
    sleep sleep_duration
    thread
  end
end

RSpec.configure do |config|
  config.include ThreadsHelper

  config.around(:each, :ensure_threads_exited) do |example|
    ensure_threads_exited { example.run }
  end
end
