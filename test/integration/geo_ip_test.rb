require 'integration_test_helper'

class GeoIpTest < ActiveSupport::TestCase

  # check
  test 'check some results' do

    result = Service::GeoIp.location('127.0.0.0.1')
    assert(result)
    assert_equal(nil, result['country_name'])
    assert_equal(nil, result['city_name'])
    assert_equal(nil, result['country_code'])
    assert_equal(nil, result['continent_code'])
    assert_equal(nil, result['latitude'])
    assert_equal(nil, result['longitude'])

    result = Service::GeoIp.location('127.0.0.1')
    assert(result)
    assert_equal(nil, result['country_name'])
    assert_equal(nil, result['city_name'])
    assert_equal(nil, result['country_code'])
    assert_equal(nil, result['continent_code'])
    assert_equal(nil, result['latitude'])
    assert_equal(nil, result['longitude'])

    result = Service::GeoIp.location('195.65.29.254')
    assert(result)
    assert_equal('Switzerland', result['country_name'])
    assert_equal('Regensdorf', result['city_name'])
    assert_equal('CH', result['country_code'])
    assert_equal('EU', result['continent_code'])
    assert_equal(47.4319, result['latitude'])
    assert_equal(8.4658, result['longitude'])

    result = Service::GeoIp.location('134.109.140.74')
    assert(result)
    assert_equal('Germany', result['country_name'])
    assert_equal('Chemnitz', result['city_name'])
    assert_equal('DE', result['country_code'])
    assert_equal('EU', result['continent_code'])
    assert_equal(50.8333, result['latitude'])
    assert_equal(12.9167, result['longitude'])

    result = Service::GeoIp.location('46.253.55.170')
    assert(result)
    assert_equal('Germany', result['country_name'])
    assert_equal('Halle', result['city_name'])
    assert_equal('DE', result['country_code'])
    assert_equal('EU', result['continent_code'])
    assert_equal(51.5034, result['latitude'])
    assert_equal(11.9622, result['longitude'])

    result = Service::GeoIp.location('169.229.216.200')
    assert(result)
    assert_equal('United States', result['country_name'])
    assert_equal('Berkeley', result['city_name'])
    assert_equal('US', result['country_code'])
    assert_equal('NA', result['continent_code'])
    assert_equal(37.8668, result['latitude'])
    assert_equal(-122.2536, result['longitude'])

    result = Service::GeoIp.location('17.171.2.25')
    assert(result)
    assert_equal('United States', result['country_name'])
    assert_equal('Cupertino', result['city_name'])
    assert_equal('US', result['country_code'])
    assert_equal('NA', result['continent_code'])
    assert_equal(37.323, result['latitude'])
    assert_equal(-122.0322, result['longitude'])

  end
end
