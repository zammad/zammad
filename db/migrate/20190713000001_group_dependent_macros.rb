# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class GroupDependentMacros < ActiveRecord::Migration[4.2]
  def up

    create_table :groups_macros, id: false do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :macro, null: false
      t.references :group, null: false
    end
    add_index :groups_macros, [:macro_id]
    add_index :groups_macros, [:group_id]
    add_foreign_key :groups_macros, :macros
    add_foreign_key :groups_macros, :groups

  end

  def self.down
    drop_table :groups_macros
  end
end
