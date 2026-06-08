# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddReportProfilesRoles < ActiveRecord::Migration[4.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :report_profiles_roles, id: false do |t|
      t.references :profile, null: false, foreign_key: { to_table: :report_profiles }, index: true
      t.references :role, null: false, foreign_key: true, index: true
    end
  end
end
