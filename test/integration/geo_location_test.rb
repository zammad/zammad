# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'integration_test_helper'
require 'webmock/minitest'

class GeoLocationTest < ActiveSupport::TestCase

  setup do
    @mock = true
    #WebMock.allow_net_connect!
  end

  # check
  test 'check simple results' do

    if @mock
      stub_request(:get, 'http://maps.googleapis.com/maps/api/geocode/json?address=Marienstrasse%2013,%2010117%20Berlin&sensor=true')
        .to_return(status: 200, body: '{"results":[{"geometry":{"location":{"lat": 52.5219143, "lng": 13.3832647}}}]}', headers: {})
    end

    result = Service::GeoLocation.geocode('Marienstrasse 13, 10117 Berlin')
    assert(result)
    assert_equal(52.5219143, result[0])
    assert_equal(13.3832647, result[1])

    if @mock
      stub_request(:get, 'http://maps.googleapis.com/maps/api/geocode/json?address=Marienstrasse%2013%2010117%20Berlin&sensor=true')
        .to_return(status: 200, body: '{"results":[{"geometry":{"location":{"lat": 52.5219143, "lng": 13.3832647}}}]}', headers: {})
    end

    result = Service::GeoLocation.geocode('Marienstrasse 13 10117 Berlin')
    assert(result)
    assert_equal(52.5219143, result[0])
    assert_equal(13.3832647, result[1])

    if @mock
      stub_request(:get, 'http://maps.googleapis.com/maps/api/geocode/json?address=Martinsbruggstrasse%2035,%209016%20St.%20Gallen&sensor=true')
        .to_return(status: 200, body: '{"results":[{"geometry":{"location":{"lat": 47.4366557, "lng": 9.4098904}}}]}', headers: {})
    end

    result = Service::GeoLocation.geocode('Martinsbruggstrasse 35, 9016 St. Gallen')
    assert(result)
    assert_equal(47.4366557, result[0])
    assert_equal(9.4098904, result[1])

    if @mock
      stub_request(:get, 'http://maps.googleapis.com/maps/api/geocode/json?address=Martinsbruggstrasse%2035%209016%20St.%20Gallen&sensor=true')
        .to_return(status: 200, body: '{"results":[{"geometry":{"location":{"lat": 47.4366557, "lng": 9.4098904}}}]}', headers: {})
    end

    result = Service::GeoLocation.geocode('Martinsbruggstrasse 35 9016 St. Gallen')
    assert(result)
    assert_equal(47.4366557, result[0])
    assert_equal(9.4098904, result[1])

  end

  test 'check user results' do

    if @mock
      stub_request(:get, 'http://maps.googleapis.com/maps/api/geocode/json?address=Marienstrasse%2013%2010117%20Berlin&sensor=true')
        .to_return(status: 200, body: '{"results":[{"geometry":{"location":{"lat": 52.5219143, "lng": 13.3832647}}}]}', headers: {})
    end

    user1 = User.create(
      login:         'some_geo_login1',
      firstname:     'First',
      lastname:      'Last',
      email:         'some_geo_login1@example.com',
      password:      'test',
      address:       'Marienstrasse 13 10117 Berlin',
      active:        false,
      updated_by_id: 1,
      created_by_id: 1
    )
    assert(user1.preferences)
    assert(user1.preferences['lat'])
    assert(user1.preferences['lng'])
    assert_equal(52.5219143, user1.preferences['lat'])
    assert_equal(13.3832647, user1.preferences['lng'])

    if @mock
      stub_request(:get, 'http://maps.googleapis.com/maps/api/geocode/json?address=Marienstrasse%2013,%2010117,%20Berlin&sensor=true')
        .to_return(status: 200, body: '{"results":[{"geometry":{"location":{"lat": 52.5219143, "lng": 13.3832647}}}]}', headers: {})
    end

    user2 = User.create(
      login:         'some_geo_login2',
      firstname:     'First',
      lastname:      'Last',
      email:         'some_geo_login2@example.com',
      password:      'test',
      street:        'Marienstrasse 13',
      city:          'Berlin',
      zip:           '10117',
      active:        false,
      updated_by_id: 1,
      created_by_id: 1
    )
    assert(user2.preferences)
    assert(user2.preferences['lat'])
    assert(user2.preferences['lng'])
    assert_equal(52.5219143, user2.preferences['lat'])
    assert_equal(13.3832647, user2.preferences['lng'])

    if @mock
      stub_request(:get, 'http://maps.googleapis.com/maps/api/geocode/json?address=Martinsbruggstrasse%2035,%209016%20St.%20Gallen&sensor=true')
        .to_return(status: 200, body: '{"results":[{"geometry":{"location":{"lat": 47.4366557, "lng": 9.4098904}}}]}', headers: {})
    end

    user3 = User.create(
      login:         'some_geo_login3',
      firstname:     'First',
      lastname:      'Last',
      email:         'some_geo_login3@example.com',
      password:      'test',
      address:       'Martinsbruggstrasse 35, 9016 St. Gallen',
      active:        false,
      updated_by_id: 1,
      created_by_id: 1
    )
    assert(user3.preferences)
    assert(user3.preferences['lat'])
    assert(user3.preferences['lng'])
    assert_equal(47.4366557, user3.preferences['lat'])
    assert_equal(9.4098904, user3.preferences['lng'])

    if @mock
      stub_request(:get, 'http://maps.googleapis.com/maps/api/geocode/json?address=Martinsbruggstrasse%2035,%209016,%20St.%20Gallen&sensor=true')
        .to_return(status: 200, body: '{"results":[{"geometry":{"location":{"lat": 47.4366557, "lng": 9.4098904}}}]}', headers: {})
    end

    user4 = User.create(
      login:         'some_geo_login4',
      firstname:     'First',
      lastname:      'Last',
      email:         'some_geo_login4@example.com',
      password:      'test',
      street:        'Martinsbruggstrasse 35',
      city:          'St. Gallen',
      zip:           '9016',
      active:        false,
      updated_by_id: 1,
      created_by_id: 1
    )
    assert(user4.preferences)
    assert(user4.preferences['lat'])
    assert(user4.preferences['lng'])
    assert_equal(47.4366557, user4.preferences['lat'])
    assert_equal(9.4098904, user4.preferences['lng'])

  end
end
