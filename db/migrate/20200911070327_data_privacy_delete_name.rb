# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class DataPrivacyDeleteName < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    remove_column :data_privacy_tasks, :name, :string, limit: 150
  end
end
