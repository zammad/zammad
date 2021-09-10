# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3168TokenSetting < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'api_token_access').update(frontend: true)
  end
end
