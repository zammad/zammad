class CreateNetwork < ActiveRecord::Migration
  def up
    create_table :networks do |t|
      t.column :name,                 :string, limit: 100, null: false
      t.column :note,                 :string, limit: 250, null: true
      t.column :active,               :boolean,               null: false, default: true
      t.column :updated_by_id,        :integer,               null: false
      t.column :created_by_id,        :integer,               null: false
      t.timestamps limit: 3, null: false
    end
    add_index :networks, [:name], unique: true

    create_table :network_category_types do |t|
      t.column :name,                 :string, limit: 100, null: false
      t.column :note,                 :string, limit: 250, null: true
      t.column :active,               :boolean,               null: false, default: true
      t.column :updated_by_id,        :integer,               null: false
      t.column :created_by_id,        :integer,               null: false
      t.timestamps limit: 3, null: false
    end
    add_index :network_category_types, [:name], unique: true

    create_table :network_privacies do |t|
      t.column :name,                 :string, limit: 100, null: false
      t.column :key,                  :string, limit: 250, null: false
      t.column :updated_by_id,        :integer,               null: false
      t.column :created_by_id,        :integer,               null: false
      t.timestamps limit: 3, null: false
    end
    add_index :network_privacies, [:name], unique: true

    create_table :network_categories do |t|
      t.references :network_category_type,                    null: false
      t.references :network_privacy,                          null: false
      t.references :network,                                  null: false
      t.column :name,                 :string, limit: 200, null: false
      t.column :note,                 :string, limit: 250, null: true
      t.column :allow_comments,       :boolean,               null: false, default: true
      t.column :active,               :boolean,               null: false, default: true
      t.column :updated_by_id,        :integer,               null: false
      t.column :created_by_id,        :integer,               null: false
      t.timestamps limit: 3, null: false
    end
    add_index :network_categories, [:network_id]

    create_table :network_categories_moderator_users, id: false do |t|
      t.integer :user_id
      t.integer :network_category_id
    end

    create_table :network_items do |t|
      t.references :network_category,                     null: false
      t.column :title,                :string, limit: 200,   null: false
      t.column :body,                 :string, limit: 20_000, null: false
      t.column :updated_by_id,        :integer,                 null: false
      t.column :created_by_id,        :integer,                 null: false
      t.timestamps                                              null: false
    end
    add_index :network_items, [:network_category_id]

    create_table :network_item_comments do |t|
      t.references :network_item,                               null: false
      t.column :body,                 :string, limit: 20_000, null: false
      t.column :updated_by_id,        :integer,               null: false
      t.column :created_by_id,        :integer,               null: false
      t.timestamps limit: 3, null: false
    end
    add_index :network_item_comments, [:network_item_id]

    create_table :network_item_plus do |t|
      t.references :network_item,                             null: false
      t.column :updated_by_id,        :integer,               null: false
      t.column :created_by_id,        :integer,               null: false
      t.timestamps limit: 3, null: false
    end
    add_index :network_item_plus, [:network_item_id, :created_by_id], unique: true

    create_table :network_category_subscriptions do |t|
      t.references :network_categories,                       null: false
      t.column :updated_by_id,        :integer,               null: false
      t.column :created_by_id,        :integer,               null: false
      t.timestamps limit: 3, null: false
    end
    add_index :network_category_subscriptions, [:network_categories_id, :created_by_id], unique: true, name: 'index_network_category_subscriptions_on_network_c_i_and_c'

    create_table :network_item_subscriptions do |t|
      t.references :network_item,                             null: false
      t.column :updated_by_id,        :integer,               null: false
      t.column :created_by_id,        :integer,               null: false
      t.timestamps limit: 3, null: false
    end
    add_index :network_item_subscriptions, [:network_item_id, :created_by_id], unique: true, name: 'index_network_item_subscriptions_on_item_id_and_created_by_id'

  end

  def down
    drop_table :network_item_subscriptions
    drop_table :network_category_subscriptions
    drop_table :network_categories_moderator_users
    drop_table :network_item_plus
    drop_table :network_item_comments
    drop_table :network_items
    drop_table :network_categories
    drop_table :network_privacies
    drop_table :network_category_types
    drop_table :networks
  end
end
