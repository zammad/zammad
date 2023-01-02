# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class DropTextModuleForeignId < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    remove_column :text_modules, :foreign_id, :integer
    TextModule.reset_column_information
  end
end
