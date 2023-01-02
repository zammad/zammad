# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SessionTimeoutDescription < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'session_timeout').update(description: 'Defines the session timeout for inactivity of users. Based on the assigned permissions the highest timeout value will be used, otherwise the default.')
  end
end
