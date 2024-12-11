# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module BackgroundServices::Concerns::HasInterruptibleSleep
  extend ActiveSupport::Concern

  # Sleep in short intervals so that we can handle TERM/INT signals timely.
  # @param [Integer] seconds to sleep for
  def interruptible_sleep(interval)
    interval.times do
      break if BackgroundServices.shutdown_requested

      sleep 1
    end
  end

end
