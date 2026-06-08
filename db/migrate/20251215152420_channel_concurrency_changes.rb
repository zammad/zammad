# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ChannelConcurrencyChanges < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Scheduler
      .find_by!(method: 'Channel.fetch')
      .update!(method: 'Channel.fetch_async')
  end
end
