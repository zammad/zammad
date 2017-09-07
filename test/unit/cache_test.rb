# encoding: utf-8
require 'test_helper'

class CacheTest < ActiveSupport::TestCase
  test 'cache' do

    # test 1
    Cache.write('123', 'some value')
    cache = Cache.get('123')
    assert_equal(cache, 'some value')

    Cache.write('123', { key: 'some value' })
    cache = Cache.get('123')
    assert_equal(cache, { key: 'some value' })

    # test 2
    Cache.write('123', { key: 'some valueöäüß' })
    cache = Cache.get('123')
    assert_equal(cache, { key: 'some valueöäüß' })

    # test 3
    Cache.delete('123')
    cache = Cache.get('123')
    assert_nil(cache)

    # test 4
    Cache.write('123', { key: 'some valueöäüß2' })
    cache = Cache.get('123')
    assert_equal(cache, { key: 'some valueöäüß2' })

    Cache.delete('123')
    cache = Cache.get('123')
    assert_nil(cache)

    # test 5
    Cache.clear
    cache = Cache.get('123')
    assert_nil(cache)

    Cache.delete('123')
    cache = Cache.get('123')
    assert_nil(cache)

    # test 6
    Cache.write('123', { key: 'some valueöäüß2' }, expires_in: 3.seconds)
    travel 5.seconds
    cache = Cache.get('123')
    assert_nil(cache)
  end

  # verify if second cache write overwrite first one
  test 'cache reset' do
    Cache.write('some_reset_key', 123)
    Cache.write('some_reset_key', 12_356)
    cache = Cache.get('some_reset_key')
    assert_equal(cache, 12_356, 'verify')
  end
end
