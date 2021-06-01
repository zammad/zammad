# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ObjectManagerAttributeIndexes < ActiveRecord::Migration[5.1]
  def change

    add_index :object_manager_attributes, :active
    add_index :object_manager_attributes, :updated_at
  end
end
