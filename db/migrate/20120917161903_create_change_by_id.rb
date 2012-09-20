class CreateChangeById < ActiveRecord::Migration
  def up
    add_column :channels, :updated_by_id,          :integer, :null => true
    add_column :overviews, :created_by_id,          :integer, :null => true
    add_column :overviews, :updated_by_id,          :integer, :null => true
    add_column :users, :updated_by_id,          :integer, :null => true
    add_column :signatures, :updated_by_id,          :integer, :null => true
    add_column :groups, :updated_by_id,          :integer, :null => true
    add_column :roles, :updated_by_id,          :integer, :null => true
    add_column :organizations, :updated_by_id,          :integer, :null => true
    add_column :ticket_state_types, :updated_by_id,          :integer, :null => true
    add_column :ticket_state_types, :created_by_id,          :integer, :null => true
    add_column :ticket_states, :updated_by_id,          :integer, :null => true
    add_column :ticket_states, :created_by_id,          :integer, :null => true
    add_column :ticket_priorities, :updated_by_id,          :integer, :null => true
    add_column :ticket_priorities, :created_by_id,          :integer, :null => true
    add_column :tickets, :updated_by_id,          :integer, :null => true
    add_column :ticket_article_types, :updated_by_id,          :integer, :null => true
    add_column :ticket_article_types, :created_by_id,          :integer, :null => true
    add_column :ticket_article_senders, :updated_by_id,          :integer, :null => true
    add_column :ticket_article_senders, :created_by_id,          :integer, :null => true
    add_column :ticket_articles, :updated_by_id,          :integer, :null => true
    add_column :networks, :updated_by_id,          :integer, :null => true
    add_column :networks, :created_by_id,          :integer, :null => true
    add_column :network_category_types, :updated_by_id,          :integer, :null => true
    add_column :network_category_types, :created_by_id,          :integer, :null => true
    add_column :network_privacies, :updated_by_id,          :integer, :null => true
    add_column :network_privacies, :created_by_id,          :integer, :null => true
    add_column :network_categories, :updated_by_id,          :integer, :null => true
    add_column :network_categories, :created_by_id,          :integer, :null => true
    add_column :network_items, :updated_by_id,          :integer, :null => true
    add_column :network_item_comments, :updated_by_id,          :integer, :null => true
    add_column :network_item_plus, :updated_by_id,          :integer, :null => true
    add_column :network_category_subscriptions, :updated_by_id,          :integer, :null => true
    add_column :network_item_subscriptions, :updated_by_id,          :integer, :null => true
    add_column :templates, :created_by_id,          :integer, :null => true
    add_column :templates, :updated_by_id,          :integer, :null => true
    add_column :translations, :created_by_id,          :integer, :null => true
    add_column :translations, :updated_by_id,          :integer, :null => true
  end

  def down
  end
end
