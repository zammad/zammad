# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class EmailAddressesEmailMatchUserEmail < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_column :email_addresses, :email, :string, limit: 255

    EmailAddress.reset_column_information
  end
end
