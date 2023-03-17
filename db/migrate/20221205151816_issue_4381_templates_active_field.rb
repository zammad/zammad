# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4381TemplatesActiveField < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_table :templates do |t|
      t.boolean :active, default: true, null: false
    end

    Template.reset_column_information
  end
end
