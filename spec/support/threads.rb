# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
      break if superfluous_threads.call.none?

      sleep 1 # Wait a bit for stuff to settle before trying again.
    end

    if superfluous_threads.call.any?
      superfluous_threads.call.each do |thread|
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
  def ensure_block_keeps_running(timeout: 2.seconds, &)
    # Stop after timeout and return true if everything was ok.
    # Suppress the Rails logger as its exception may rescue our TimeoutErrors, causing failures here.
    Rails.logger.silence do
      Timeout.timeout(timeout, &)
    end
    raise 'Process ended unexpectedly.'
  rescue SystemExit
    # Convert SystemExit to a RuntimeError as otherwise rspec will shut down without an error.
    raise 'Process tried to shut down unexpectedly.'
  rescue Timeout::Error
    # Default case: process started fine and kept running, interrupted by timeout.
    true
  end

  # Runs write in a transaction on a second connection and yields its result. That transaction
  #   commits only once the block's connection waits for one of its locks, so the block runs into
  #   the uncommitted row like a concurrent request would. Transactional tests pin every thread to
  #   one connection, so this needs `self.use_transactional_tests = false`.
  def with_uncommitted_concurrent_write(write)
    waiting_pid = ActiveRecord::Base.connection.select_value('SELECT pg_backend_pid()')
    written     = Queue.new

    concurrent = Thread.new do
      UserInfo.current_user_id = 1

      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.transaction do
          written << write.call
          wait_until_backend_waits_for_lock(connection, waiting_pid)
        end
      end
    rescue => e
      written << e
      raise
    end

    result = written.pop
    raise result if result.is_a?(Exception)

    yield result
  ensure
    concurrent&.join
  end

  private

  def wait_until_backend_waits_for_lock(connection, pid)
    deadline = 10.seconds.from_now
    query    = ActiveRecord::Base.sanitize_sql_array(['SELECT wait_event_type FROM pg_stat_activity WHERE pid = ?', pid])

    until connection.select_value(query) == 'Lock'
      raise 'The concurrent write was never waited for.' if Time.current > deadline

      sleep 0.01
    end
  end
end

RSpec.configure do |config|
  config.include ThreadsHelper

  config.around(:each, :ensure_threads_exited) do |example|
    ensure_threads_exited { example.run }
  end
end
