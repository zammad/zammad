# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue2867FooterHeaderPublicLink < ActiveRecord::Migration[5.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column            :knowledge_base_menu_items, :location, :string, null: false, default: 'header'
    add_index             :knowledge_base_menu_items, :location
    change_column_default :knowledge_base_menu_items, :location, nil
  end

  def down
    remove_column :knowledge_base_menu_items, :location
  end
end
