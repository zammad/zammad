class CreateCtiLog < ActiveRecord::Migration
  def up
    create_table :cti_logs do |t|
      t.string  :direction,              limit: 20,   null: false
      t.string  :state,                  limit: 20,   null: false
      t.string  :from,                   limit: 100,  null: false
      t.string  :from_comment,           limit: 250,  null: true
      t.string  :to,                     limit: 100,  null: false
      t.string  :to_comment,             limit: 250,  null: true
      t.string  :call_id,                limit: 250,  null: false
      t.string  :comment,                limit: 500,  null: true
      t.timestamp :start,                             null: true
      t.timestamp :end,                               null: true
      t.boolean   :done,                              null: false, default: true
      t.text :preferences,            limit: 500.kilobytes + 1, null: true
      t.timestamps null: false
    end
    add_index :cti_logs, [:call_id], unique: true
    add_index :cti_logs, [:direction]
    add_index :cti_logs, [:from]

    create_table :cti_caller_ids do |t|
      t.string  :caller_id,              limit: 100, null: false
      t.string  :comment,                limit: 500, null: true
      t.string  :level,                  limit: 100, null: false
      t.string  :object,                 limit: 100, null: false
      t.integer :o_id,                               null: false
      t.integer :user_id,                            null: true
      t.text    :preferences,            limit: 500.kilobytes + 1, null: true
      t.timestamps null: false
    end
    add_index :cti_caller_ids, [:caller_id]
    add_index :cti_caller_ids, [:caller_id, :level]
    add_index :cti_caller_ids, [:caller_id, :user_id]
    add_index :cti_caller_ids, [:object, :o_id]

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Role.create_if_not_exists(
      name: 'CTI',
      note: 'Access to CTI feature.',
      updated_by_id: 1,
      created_by_id: 1
    )

    Setting.create_if_not_exists(
      title: 'Define transaction backend.',
      name: '9100_cti_caller_id_detection',
      area: 'Transaction::Backend::Async',
      description: 'Define the transaction backend which detects caller ids in objects and store them for cti lookups.',
      options: {},
      state: 'Transaction::CtiCallerIdDetection',
      frontend: false
    )

  end
end
