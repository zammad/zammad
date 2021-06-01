# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class RemoveNetwork < ActiveRecord::Migration[5.0]

  # rewinds db/migrate/20120101000020_create_network.rb
  def change
    return if !ActiveRecord::Base.connection.table_exists? 'networks'

    # rubocop:disable Rails/ReversibleMigration
    drop_table :networks
    drop_table :network_category_types
    drop_table :network_privacies
    drop_table :network_categories
    drop_table :network_categories_moderator_users
    drop_table :network_items
    drop_table :network_item_comments
    drop_table :network_item_plus
    drop_table :network_category_subscriptions
    drop_table :network_item_subscriptions
    # rubocop:enable Rails/ReversibleMigration
  end
end
