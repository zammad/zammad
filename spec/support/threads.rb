# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ThreadsHelper
  # Ensure that any new threads which might be spawned by the block will be cleaned up
  #   to not interfere with any subsequent tests.
  def ensure_threads_exited()
    initial_threads = Thread.list
    yield
  ensure
    superfluous_threads = -> { Thread.list - initial_threads }

    # Keep going until no more changes are needed to catch threads spawned in between.
    3.times do
      superfluous_threads.call.each do |t|
        t.kill
        t.join # From `Timeout.timeout`: make sure thread is dead.
      end
      break if superfluous_threads.call.count.zero?

      sleep 1 # Wait a bit for stuff to settle before trying again.
    end

    if superfluous_threads.call.count.positive?
      superfluous_threads.each do |thread|
        warn "Error: found a superfluous thread after clean-up: #{thread}"
        warn "Backtrace: #{thread.backtrace.join("\n")}"
      end
      raise 'Superfluous threads found after clean-up.'
    end

    # Sometimes connections are not checked back in after thread is killed
    # This recovers connections from the workers
    ActiveRecord::Base.connection_pool.reap
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
end

RSpec.configure do |config|
  config.include ThreadsHelper

  config.around(:each, :ensure_threads_exited) do |example|
    ensure_threads_exited { example.run }
  end
end
