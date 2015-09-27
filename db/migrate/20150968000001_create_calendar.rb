class CreateCalendar < ActiveRecord::Migration
  def up
    create_table :calendars do |t|
      t.string  :name,                   limit: 250, null: true
      t.string  :timezone,               limit: 250, null: true
      t.string  :business_hours,         limit: 1200, null: true
      t.boolean :default,                            null: false, default: false
      t.string  :ical_url,               limit: 500, null: true
      t.text    :public_holidays,        limit: 500.kilobytes + 1, null: true
      t.text    :last_log,               limit: 500.kilobytes + 1, null: true
      t.timestamp :last_sync,            null: true
      t.integer :updated_by_id,          null: false
      t.integer :created_by_id,          null: false
      t.timestamps                       null: false
    end
    add_index :calendars, [:name], unique: true

    Scheduler.create_or_update(
      name: 'Sync calendars with ical feeds.',
      method: 'Calendar.sync',
      period: 1.day,
      prio: 2,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  def down
    drop_table :calendars
  end
end
