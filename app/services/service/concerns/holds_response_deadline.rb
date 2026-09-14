# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::Concerns::HoldsResponseDeadline
  extend ActiveSupport::Concern

  # Holds a block to a fixed duration: it returns once RESPONSE_DEADLINE has passed, no matter how
  # much work it actually performed, so that the caller always answers after the same time.
  #
  # The deadline holds only as long as the work stays below it, so the block should do no more than
  # a few database queries. Anything expensive, above all the delivery of a mail, belongs in a
  # background job instead. Work which outlasts the deadline is not held back.
  #
  # The value leaves ample room for the few queries described above, while staying short enough to
  # go unnoticed on a form submission.
  RESPONSE_DEADLINE = 0.25.seconds

  private

  def with_response_deadline(&)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    yield
  ensure
    remaining = RESPONSE_DEADLINE - (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started)

    sleep(remaining) if remaining.positive?
  end
end
