# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4306DeleteSetting < ActiveRecord::Migration[6.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'es_excludes').destroy
  end
end
