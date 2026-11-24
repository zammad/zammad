# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module BackgroundServices::Concerns::HasInterruptibleSleep
  extend ActiveSupport::Concern

  # Sleep in short intervals so that we can handle TERM/INT signals timely.
  # @param [Numeric, ActiveSupport::Duration] seconds to sleep for
  def interruptible_sleep(interval)
    remaining = interval.to_f

    while remaining.positive?
      break if BackgroundServices.shutdown_requested

      step = [remaining, 1].min
      sleep step
      remaining -= step
    end
  end

end
