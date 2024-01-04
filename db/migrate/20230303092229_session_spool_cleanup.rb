# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SessionSpoolCleanup < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Sessions.spool_delete
  end
end
