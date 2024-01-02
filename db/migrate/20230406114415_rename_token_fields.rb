# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class RenameTokenFields < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    rename_column :tokens, :name,  :token
    rename_column :tokens, :label, :name

    Token.reset_column_information
  end
end
