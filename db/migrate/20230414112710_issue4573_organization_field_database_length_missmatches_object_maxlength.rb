# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Issue4573OrganizationFieldDatabaseLengthMissmatchesObjectMaxlength < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_column :organizations, :name, :string, limit: 150, null: false

    Organization.reset_column_information
  end
end
