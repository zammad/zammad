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
      t.timestamps
    end
    add_index :calendars, [:name], unique: true

    Calendar.create_or_update(
      name: 'US',
      timezone: 'America/Los_Angeles',
      business_hours: {
        mon: { '09:00' => '17:00' },
        tue: { '09:00' => '17:00' },
        wed: { '09:00' => '17:00' },
        thu: { '09:00' => '17:00' },
        fri: { '09:00' => '17:00' }
      },
      default: true,
      ical_url: 'http://www.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Calendar.create_or_update(
      name: 'Germany',
      timezone: 'Europe/Berlin',
      business_hours: {
        mon: { '09:00' => '17:00' },
        tue: { '09:00' => '17:00' },
        wed: { '09:00' => '17:00' },
        thu: { '09:00' => '17:00' },
        fri: { '09:00' => '17:00' }
      },
      default: false,
      ical_url: 'http://www.google.com/calendar/ical/de.german%23holiday%40group.v.calendar.google.com/public/basic.ics',
      updated_by_id: 1,
      created_by_id: 1,
    )
=begin
    Calendar.create_or_update(
      name: 'French',
      timezone: 'Europe/Paris',
      business_hours: {
        mon: { '09:00' => '17:00' },
        tue: { '09:00' => '17:00' },
        wed: { '09:00' => '17:00' },
        thu: { '09:00' => '12:00', '13:00' => '17:00' },
        fri: { '09:00' => '17:00' }
      },
      default: false,
      ical_url: 'http://www.google.com/calendar/ical/fr.french%23holiday%40group.v.calendar.google.com/public/basic.ics',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Calendar.create_or_update(
      name: 'Switzerland',
      timezone: 'Europe/Zurich',
      business_hours: {
        mon: { '09:00' => '17:00' },
        tue: { '09:00' => '17:00' },
        wed: { '09:00' => '17:00' },
        thu: { '09:00' => '12:00', '13:00' => '17:00' },
        fri: { '09:00' => '17:00' }
      },
      default: false,
      ical_url: 'http://www.google.com/calendar/ical/de.ch%23holiday%40group.v.calendar.google.com/public/basic.ics',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Calendar.create_or_update(
      name: 'Austria',
      timezone: 'Europe/Vienna',
      business_hours: {
        mon: { '09:00' => '17:00' },
        tue: { '09:00' => '17:00' },
        wed: { '09:00' => '17:00' },
        thu: { '09:00' => '17:00' },
        fri: { '09:00' => '17:00' }
      },
      default: false,
      ical_url: 'http://www.google.com/calendar/ical/de.austrian%23holiday%40group.v.calendar.google.com/public/basic.ics',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Calendar.create_or_update(
      name: 'Italian',
      timezone: 'Europe/Roma',
      business_hours: {
        mon: { '09:00' => '17:00' },
        tue: { '09:00' => '17:00' },
        wed: { '09:00' => '17:00' },
        thu: { '09:00' => '17:00' },
        fri: { '09:00' => '17:00' }
      },
      default: false,
      ical_url: 'http://www.google.com/calendar/ical/it.italian%23holiday%40group.v.calendar.google.com/public/basic.ics',
      updated_by_id: 1,
      created_by_id: 1,
    )
=end
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
