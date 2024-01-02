# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class RenameEmailRealname < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    rename_column :email_addresses, :realname, :name

    EmailAddress.reset_column_information
  end
end
