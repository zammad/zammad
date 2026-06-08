# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ChannelFetchJob < ApplicationJob
  include HasActiveJobLock

  EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR = :dismiss_running

  queue_as :communication_inbound

  def lock_key
    channel = arguments[0]

    "#{self.class.name}/Channel/#{channel.id}"
  end

  def perform(channel)
    channel.fetch
  end
end
