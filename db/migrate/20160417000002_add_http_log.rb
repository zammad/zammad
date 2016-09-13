class AddHttpLog < ActiveRecord::Migration
  def up

    create_table :http_logs do |t|
      t.column :direction,            :string, limit: 20,    null: false
      t.column :facility,             :string, limit: 100,   null: false
      t.column :method,               :string, limit: 100,   null: false
      t.column :url,                  :string, limit: 255,   null: false
      t.column :status,               :string, limit: 20,    null: true
      t.column :ip,                   :string, limit: 50,    null: true
      t.column :request,              :string, limit: 10_000, null: false
      t.column :response,             :string, limit: 10_000, null: false
      t.column :updated_by_id,        :integer,              null: true
      t.column :created_by_id,        :integer,              null: true
      t.timestamps limit: 3, null: false
    end
    add_index :http_logs, [:facility]
    add_index :http_logs, [:created_by_id]
    add_index :http_logs, [:created_at]

    Scheduler.create_if_not_exists(
      name: 'Cleanup HttpLog',
      method: 'HttpLog.cleanup',
      period: 24 * 60 * 60,
      prio: 2,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

  end
end
