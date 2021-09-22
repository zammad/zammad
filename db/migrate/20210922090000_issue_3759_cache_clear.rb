# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3759CacheClear < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    Cache.clear
  end
end
