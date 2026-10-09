# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CreatePushSubscriptions < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :push_subscriptions, id: :integer, if_not_exists: true do |t|
      t.references :user, null: false, type: :integer, foreign_key: { to_table: :users }
      t.string :endpoint,   limit: 2000, null: false
      t.string :p256dh,     limit: 200,  null: false
      t.string :auth,       limit: 100,  null: false
      t.timestamps limit: 3, null: false

      t.index :endpoint, unique: true
    end
  end
end
