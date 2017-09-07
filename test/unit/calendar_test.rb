# encoding: utf-8
require 'test_helper'

class CalendarTest < ActiveSupport::TestCase
  test 'default test' do
    Calendar.destroy_all
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
    travel_back
  end

  test 'sync test' do
    Calendar.destroy_all

    travel_to Time.zone.parse('2017-08-24T01:04:44Z0')

    calendar1 = Calendar.create_or_update(
      name: 'Sync 1',
      timezone: 'America/Los_Angeles',
      business_hours: {
        mon: { '09:00' => '17:00' },
        tue: { '09:00' => '17:00' },
        wed: { '09:00' => '17:00' },
        thu: { '09:00' => '17:00' },
        fri: { '09:00' => '17:00' }
      },
      default: true,
      ical_url: 'test/fixtures/calendar1.ics',
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_equal(true, calendar1.public_holidays['2016-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2016-12-24']['summary'])
    assert_nil(calendar1.public_holidays['2016-12-25'])
    assert_equal(true, calendar1.public_holidays['2017-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2017-12-24']['summary'])
    assert_nil(calendar1.public_holidays['2017-12-25'])
    assert_equal(true, calendar1.public_holidays['2018-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2018-12-24']['summary'])
    assert_nil(calendar1.public_holidays['2018-12-25'])
    assert_equal(true, calendar1.public_holidays['2019-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2019-12-24']['summary'])
    assert_nil(calendar1.public_holidays['2019-12-25'])
    assert_nil(calendar1.public_holidays['2020-12-24'])

    Calendar.sync

    assert_equal(true, calendar1.public_holidays['2016-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2016-12-24']['summary'])
    assert_nil(calendar1.public_holidays['2016-12-25'])
    assert_equal(true, calendar1.public_holidays['2017-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2017-12-24']['summary'])
    assert_nil(calendar1.public_holidays['2017-12-25'])
    assert_equal(true, calendar1.public_holidays['2018-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2018-12-24']['summary'])
    assert_nil(calendar1.public_holidays['2018-12-25'])
    assert_equal(true, calendar1.public_holidays['2019-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2019-12-24']['summary'])
    assert_nil(calendar1.public_holidays['2019-12-25'])
    assert_nil(calendar1.public_holidays['2020-12-24'])

    cache_key = "CalendarIcal::#{calendar1.id}"
    cache = Cache.get(cache_key)

    calendar1.update_columns(ical_url: 'test/fixtures/calendar2.ics')
    cache_key = "CalendarIcal::#{calendar1.id}"
    cache = Cache.get(cache_key)
    cache[:ical_url] = 'test/fixtures/calendar2.ics'
    Cache.write(
      cache_key,
      cache,
      { expires_in: 1.day },
    )

    Calendar.sync

    calendar1.reload
    assert_equal(true, calendar1.public_holidays['2016-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2016-12-24']['summary'])
    assert_nil(calendar1.public_holidays['2016-12-25'])
    assert_equal(true, calendar1.public_holidays['2017-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2017-12-24']['summary'])
    assert_nil(calendar1.public_holidays['2017-12-25'])
    assert_equal(true, calendar1.public_holidays['2018-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2018-12-24']['summary'])
    assert_nil(calendar1.public_holidays['2018-12-25'])
    assert_equal(true, calendar1.public_holidays['2019-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2019-12-24']['summary'])
    assert_nil(calendar1.public_holidays['2019-12-25'])
    assert_nil(calendar1.public_holidays['2020-12-24'])

    travel 2.days

    Calendar.sync

    calendar1.reload
    assert_equal(true, calendar1.public_holidays['2016-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2016-12-24']['summary'])
    assert_equal(true, calendar1.public_holidays['2016-12-25']['active'])
    assert_equal('Christmas2', calendar1.public_holidays['2016-12-25']['summary'])
    assert_equal(true, calendar1.public_holidays['2017-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2017-12-24']['summary'])
    assert_equal(true, calendar1.public_holidays['2017-12-25']['active'])
    assert_equal('Christmas2', calendar1.public_holidays['2017-12-25']['summary'])
    assert_equal(true, calendar1.public_holidays['2018-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2018-12-24']['summary'])
    assert_equal(true, calendar1.public_holidays['2018-12-25']['active'])
    assert_equal('Christmas2', calendar1.public_holidays['2018-12-25']['summary'])
    assert_equal(true, calendar1.public_holidays['2019-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2019-12-24']['summary'])
    assert_equal(true, calendar1.public_holidays['2019-12-25']['active'])
    assert_equal('Christmas2', calendar1.public_holidays['2019-12-25']['summary'])
    assert_nil(calendar1.public_holidays['2020-12-24'])
    assert_nil(calendar1.public_holidays['2020-12-25'])

    Calendar.destroy_all

    calendar1 = Calendar.create_or_update(
      name: 'Sync 2',
      timezone: 'America/Los_Angeles',
      business_hours: {
        mon: { '09:00' => '17:00' },
        tue: { '09:00' => '17:00' },
        wed: { '09:00' => '17:00' },
        thu: { '09:00' => '17:00' },
        fri: { '09:00' => '17:00' }
      },
      default: true,
      ical_url: 'test/fixtures/calendar3.ics',
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_equal(true, calendar1.public_holidays['2016-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2016-12-24']['summary'])
    assert_equal(true, calendar1.public_holidays['2016-12-26']['active'])
    assert_equal('day3', calendar1.public_holidays['2016-12-26']['summary'])
    assert_equal(true, calendar1.public_holidays['2016-12-28']['active'])
    assert_equal('day5', calendar1.public_holidays['2016-12-28']['summary'])
    assert_equal(true, calendar1.public_holidays['2017-01-26']['active'])
    assert_equal('day3', calendar1.public_holidays['2017-01-26']['summary'])
    assert_equal(true, calendar1.public_holidays['2017-02-26']['active'])
    assert_equal('day3', calendar1.public_holidays['2017-02-26']['summary'])
    assert_equal(true, calendar1.public_holidays['2017-03-26']['active'])
    assert_equal('day3', calendar1.public_holidays['2017-03-26']['summary'])
    assert_equal(true, calendar1.public_holidays['2017-04-26']['active'])
    assert_equal('day3', calendar1.public_holidays['2017-04-26']['summary'])
    assert_nil(calendar1.public_holidays['2017-05-26'])
    assert_equal(true, calendar1.public_holidays['2017-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2017-12-24']['summary'])
    assert_equal(true, calendar1.public_holidays['2018-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2018-12-24']['summary'])
    assert_equal(true, calendar1.public_holidays['2019-12-24']['active'])
    assert_equal('Christmas1', calendar1.public_holidays['2019-12-24']['summary'])
    assert_nil(calendar1.public_holidays['2020-12-24'])

    travel_back

  end

end
