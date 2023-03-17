# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Using older 5.0 migration to stick to Integer primary keys. Otherwise migration fails in MySQL.
class CreateKnowledgeBaseFeed < ActiveRecord::Migration[5.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    change_table :knowledge_bases do |t|
      t.boolean :show_feed_icon, default: false, null: false
    end

    KnowledgeBase.reset_column_information
  end
end
