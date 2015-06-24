class SessionChanges < ActiveRecord::Migration
  def up

    ActiveRecord::SessionStore::Session.delete_all

    remove_index :sessions, :request_type
    remove_column :sessions, :request_type

    add_column :sessions, :persistent, :boolean, null: true
    add_index :sessions, :persistent
  end

  def down

    ActiveRecord::SessionStore::Session.delete_all

    remove_index :sessions, :persistent
    remove_column :sessions, :persistent

    add_column :sessions, :request_type, :integer, null: true
    add_index :sessions, :request_type
  end

end
