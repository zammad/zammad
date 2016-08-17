# encoding: utf-8
require 'integration_test_helper'

class GeoLocationTest < ActiveSupport::TestCase

  # check
  test 'check simple results' do

    result = Service::GeoLocation.geocode('Marienstrasse 13, 10117 Berlin')
    assert(result)
    assert_equal(52.5219143, result[0])
    assert_equal(13.38319, result[1])

    result = Service::GeoLocation.geocode('Marienstrasse 13 10117 Berlin')
    assert(result)
    assert_equal(52.52204, result[0])
    assert_equal(13.38319, result[1])

    result = Service::GeoLocation.geocode('Martinsbruggstrasse 35, 9016 St. Gallen')
    assert(result)
    assert_equal(47.4366664, result[0])
    assert_equal(9.409814899999999, result[1])

    result = Service::GeoLocation.geocode('Martinsbruggstrasse 35 9016 St. Gallen')
    assert(result)
    assert_equal(47.4366664, result[0])
    assert_equal(9.409814899999999, result[1])

  end

  test 'check user results' do

    user1 = User.create(
      login: 'some_geo_login1',
      firstname: 'First',
      lastname: 'Last',
      email: 'some_geo_login1@example.com',
      password: 'test',
      address: 'Marienstrasse 13 10117 Berlin',
      active: false,
      updated_by_id: 1,
      created_by_id: 1
    )
    assert(user1.preferences)
    assert(user1.preferences['lat'])
    assert(user1.preferences['lng'])
    assert_equal(52.5219143, user1.preferences['lat'])
    assert_equal(13.38319, user1.preferences['lng'])

    user2 = User.create(
      login: 'some_geo_login2',
      firstname: 'First',
      lastname: 'Last',
      email: 'some_geo_login1@example.com',
      password: 'test',
      street: 'Marienstrasse 13',
      city: 'Berlin',
      zip: '10117',
      active: false,
      updated_by_id: 1,
      created_by_id: 1
    )
    assert(user2.preferences)
    assert(user2.preferences['lat'])
    assert(user2.preferences['lng'])
    assert_equal(52.52204, user2.preferences['lat'])
    assert_equal(13.38319, user2.preferences['lng'])

    user3 = User.create(
      login: 'some_geo_login3',
      firstname: 'First',
      lastname: 'Last',
      email: 'some_geo_login3@example.com',
      password: 'test',
      address: 'Martinsbruggstrasse 35, 9016 St. Gallen',
      active: false,
      updated_by_id: 1,
      created_by_id: 1
    )
    assert(user3.preferences)
    assert(user3.preferences['lat'])
    assert(user3.preferences['lng'])
    assert_equal(47.4366664, user3.preferences['lat'])
    assert_equal(9.409814899999999, user3.preferences['lng'])

    user4 = User.create(
      login: 'some_geo_login4',
      firstname: 'First',
      lastname: 'Last',
      email: 'some_geo_login4@example.com',
      password: 'test',
      street: 'Martinsbruggstrasse 35',
      city: 'St. Gallen',
      zip: '9016',
      active: false,
      updated_by_id: 1,
      created_by_id: 1
    )
    assert(user4.preferences)
    assert(user4.preferences['lat'])
    assert(user4.preferences['lng'])
    assert_equal(47.4366664, user4.preferences['lat'])
    assert_equal(9.409814899999999, user4.preferences['lng'])

  end
end
