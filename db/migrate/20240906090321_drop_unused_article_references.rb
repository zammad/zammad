# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class DropUnusedArticleReferences < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    remove_column :ticket_articles, :references

    Ticket::Article.reset_column_information
  end
end
