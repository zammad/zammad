# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TreeSelect < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_column :object_manager_attributes, :data_option, :text, limit: 800.kilobytes + 1, null: true
    change_column :object_manager_attributes, :data_option_new, :text, limit: 800.kilobytes + 1, null: true
  end
end
