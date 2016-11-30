# encoding: utf-8
require 'test_helper'

class CalendarTest < ActiveSupport::TestCase
  test 'default test' do
    Calendar.delete_all
    calendar1 = Calendar.create_or_update(
      name: 'US 1',
      timezone: 'America/Los_Angeles',
      business_hours: {
        mon: { '09:00' => '17:00' },
        tue: { '09:00' => '17:00' },
        wed: { '09:00' => '17:00' },
        thu: { '09:00' => '17:00' },
        fri: { '09:00' => '17:00' }
      },
      default: true,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )
    travel 1.second
    calendar2 = Calendar.create_or_update(
      name: 'US 2',
      timezone: 'America/Los_Angeles',
      business_hours: {
        mon: { '09:00' => '17:00' },
        tue: { '09:00' => '17:00' },
        wed: { '09:00' => '17:00' },
        thu: { '09:00' => '17:00' },
        fri: { '09:00' => '17:00' }
      },
      default: false,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )

    calendar3 = Calendar.create_or_update(
      name: 'US 3',
      timezone: 'America/Los_Angeles',
      business_hours: {
        mon: { '09:00' => '17:00' },
        tue: { '09:00' => '17:00' },
        wed: { '09:00' => '17:00' },
        thu: { '09:00' => '17:00' },
        fri: { '09:00' => '17:00' }
      },
      default: true,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )

    calendar1 = Calendar.find_by(name: 'US 1')
    calendar2 = Calendar.find_by(name: 'US 2')
    calendar3 = Calendar.find_by(name: 'US 3')

    assert_equal(false, calendar1.default)
    assert_equal(false, calendar2.default)
    assert_equal(true, calendar3.default)

    calendar2.default = true
    calendar2.save

    calendar1 = Calendar.find_by(name: 'US 1')
    calendar2 = Calendar.find_by(name: 'US 2')
    calendar3 = Calendar.find_by(name: 'US 3')

    assert_equal(false, calendar1.default)
    assert_equal(true, calendar2.default)
    assert_equal(false, calendar3.default)

    calendar2.default = false
    calendar2.save

    calendar1 = Calendar.find_by(name: 'US 1')
    calendar2 = Calendar.find_by(name: 'US 2')
    calendar3 = Calendar.find_by(name: 'US 3')

    assert_equal(true, calendar1.default)
    assert_equal(false, calendar2.default)
    assert_equal(false, calendar3.default)

    calendar1.destroy
    calendar2 = Calendar.find_by(name: 'US 2')
    calendar3 = Calendar.find_by(name: 'US 3')

    assert_equal(true, calendar2.default)
    assert_equal(false, calendar3.default)
  end

end
