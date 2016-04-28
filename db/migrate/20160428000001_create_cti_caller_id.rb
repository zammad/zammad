class CreateCtiCallerId < ActiveRecord::Migration
  def up

    create_table :cti_caller_ids do |t|
      t.string  :caller_id,              limit: 100, null: false
      t.string  :comment,                limit: 500, null: true
      t.string  :level,                  limit: 100, null: false
      t.string  :object,                 limit: 100, null: false
      t.integer :o_id,                               null: false
      t.integer :user_id,                            null: true
      t.timestamps                                   null: false
    end
    add_index :cti_caller_ids, [:caller_id]
    add_index :cti_caller_ids, [:caller_id, :level]
    add_index :cti_caller_ids, [:caller_id, :user_id]
    add_index :cti_caller_ids, [:object, :o_id]

  end
end
