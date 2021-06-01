# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class OverviewRoleIds < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :overviews_roles, id: false do |t|
      t.integer :overview_id
      t.integer :role_id
    end
    add_index :overviews_roles, [:overview_id]
    add_index :overviews_roles, [:role_id]
    Overview.connection.schema_cache.clear!
    Overview.reset_column_information
    Overview.all.each do |overview|
      next if overview.role_id.blank?

      overview.role_ids = [overview.role_id]
      overview.save!
    end
    remove_column :overviews, :role_id

    Cache.clear
  end

end
