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
      t.timestamps                                    null: false
    end
    add_index :cti_logs, [:call_id], unique: true
    add_index :cti_logs, [:direction]
    add_index :cti_logs, [:from]

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Role.create_if_not_exists(
      name: 'CTI',
      note: 'Access to CTI feature.',
      updated_by_id: 1,
      created_by_id: 1
    )

  end
end
