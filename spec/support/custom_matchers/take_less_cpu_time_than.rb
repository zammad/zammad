# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Measures the CPU time of the current thread instead of the wall-clock time, so that
#   a busy CI runner does not make the block look slow. The wall-clock timeout only
#   stops a block that hangs.
RSpec::Matchers.define :take_less_cpu_time_than do |limit|
  supports_block_expectations

  match do |block|
    Timeout.timeout(limit * 10) do
      started_at = Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID)
      block.call
      @cpu_time = Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID) - started_at
    end

    @cpu_time < limit
  end

  failure_message do
    "expected block to take less than #{limit}s of CPU time, but it took #{@cpu_time.round(3)}s"
  end
end
