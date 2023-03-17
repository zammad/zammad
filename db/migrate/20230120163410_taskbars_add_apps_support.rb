# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TaskbarsAddAppsSupport < ActiveRecord::Migration[6.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_table :taskbars do |t|
      t.remove :client_id
      t.column :app, :string, null: false, default: 'desktop'
    end

    Taskbar.reset_column_information
  end
end
