class CreateStatsStore < ActiveRecord::Migration
  def up
    create_table :stats_stores do |t|
      t.references :stats_store_object,             null: false
      t.integer :o_id,                              null: false
      t.string  :key,                   limit: 250, null: true
      t.integer :related_o_id,                      null: true
      t.integer :related_stats_store_object_id,     null: true
      t.string  :data,                 limit: 2500, null: true
      t.integer :created_by_id,                     null: false
      t.timestamps limit: 3, null: false
    end
    add_index :stats_stores, [:o_id]
    add_index :stats_stores, [:key]
    add_index :stats_stores, [:stats_store_object_id]
    add_index :stats_stores, [:created_by_id]
    add_index :stats_stores, [:created_at]

    Scheduler.create_or_update(
      name: 'Generate user based stats.',
      method: 'Stats.generate',
      period: 11.minutes,
      prio: 2,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Scheduler.create_or_update(
      name: 'Delete old stats store entries.',
      method: 'StatsStore.cleanup',
      period: 31.days,
      prio: 2,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  def down
    drop_table :stats_stores
  end
end
