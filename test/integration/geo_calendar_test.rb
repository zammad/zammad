# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'integration_test_helper'

class GeoIpCalendar < ActiveSupport::TestCase

  # check
  test 'check some results' do

    result = Service::GeoCalendar.location('127.0.0.0.1')
    assert(result)
    assert_equal('My Calendar', result['name'])
    assert_equal('America/Los_Angeles', result['timezone'])
    assert_equal('', result['ical_url'])

    result = Service::GeoCalendar.location('127.0.0.1')
    assert(result)
    assert_equal('My Calendar', result['name'])
    assert_equal('America/Los_Angeles', result['timezone'])
    assert_equal('', result['ical_url'])

    result = Service::GeoCalendar.location('195.65.29.254')
    assert(result)
    assert_equal('Switzerland', result['name'])
    assert_equal('Europe/Zurich', result['timezone'])
    assert_equal('http://www.google.com/calendar/ical/de.ch%23holiday%40group.v.calendar.google.com/public/basic.ics', result['ical_url'])

    result = Service::GeoCalendar.location('195.191.132.18')
    assert(result)
    assert_equal('Switzerland', result['name'])
    assert_equal('Europe/Zurich', result['timezone'])
    assert_equal('http://www.google.com/calendar/ical/de.ch%23holiday%40group.v.calendar.google.com/public/basic.ics', result['ical_url'])

    result = Service::GeoCalendar.location('134.109.140.74')
    assert(result)
    assert_equal('Germany', result['name'])
    assert_equal('Europe/Berlin', result['timezone'])
    assert_equal('http://www.google.com/calendar/ical/de.german%23holiday%40group.v.calendar.google.com/public/basic.ics', result['ical_url'])

    result = Service::GeoCalendar.location('46.253.55.170')
    assert(result)
    assert_equal('Germany', result['name'])
    assert_equal('Europe/Berlin', result['timezone'])
    assert_equal('http://www.google.com/calendar/ical/de.german%23holiday%40group.v.calendar.google.com/public/basic.ics', result['ical_url'])

    result = Service::GeoCalendar.location('169.229.216.200')
    assert(result)
    assert_equal('United States/California', result['name'])
    assert_equal('America/Los_Angeles', result['timezone'])
    assert_equal('http://www.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics', result['ical_url'])

    result = Service::GeoCalendar.location('17.171.2.25')
    assert(result)
    assert_equal('United States', result['name'])
    assert_equal('America/Chicago', result['timezone'])
    assert_equal('http://www.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics', result['ical_url'])

    result = Service::GeoCalendar.location('184.168.47.225')
    assert(result)
    assert_equal('United States', result['name'])
    assert_equal('America/Chicago', result['timezone'])
    assert_equal('http://www.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics', result['ical_url'])

    result = Service::GeoCalendar.location('69.172.201.245')
    assert(result)
    assert_equal('Canada', result['name'])
    assert_equal('America/Toronto', result['timezone'])
    assert_equal('http://www.google.com/calendar/ical/en.canadian%23holiday%40group.v.calendar.google.com/public/basic.ics', result['ical_url'])

    result = Service::GeoCalendar.location('132.247.70.37')
    assert(result)
    assert_equal('Mexico/Mexico City', result['name'])
    assert_equal('America/Mexico_City', result['timezone'])
    assert_equal('http://www.google.com/calendar/ical/en.mexican%23holiday%40group.v.calendar.google.com/public/basic.ics', result['ical_url'])

  end
end
