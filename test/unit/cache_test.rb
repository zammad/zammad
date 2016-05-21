# encoding: utf-8
require 'test_helper'

class CacheTest < ActiveSupport::TestCase
  test 'cache' do
    tests = [

      # test 1
      {
        set: {
          key: '123',
          data: {
            key: 'some value',
          }
        },
        verify: {
          key: '123',
          data: {
            key: 'some value',
          }
        },
      },

      # test 2
      {
        set: {
          key: '123',
          data: {
            key: 'some valueöäüß',
          }
        },
        verify: {
          key: '123',
          data: {
            key: 'some valueöäüß',
          }
        },
      },

      # test 3
      {
        delete: {
          key: '123',
        },
        verify: {
          key: '123',
          data: nil
        },
      },

      # test 4
      {
        set: {
          key: '123',
          data: {
            key: 'some valueöäüß2',
          }
        },
        verify: {
          key: '123',
          data: {
            key: 'some valueöäüß2',
          }
        },
      },

      # test 5
      {
        cleanup: true,
        verify: {
          key: '123',
          data: nil
        },
      },

      # test 6
      {
        set: {
          key: '123',
          data: {
            key: 'some valueöäüß2',
          },
          param: {
            expires_in: 3.seconds,
          }
        },
        sleep: 5,
        verify: {
          key: '123',
          data: nil
        },
      },
    ]
    tests.each { |test|
      if test[:set]
        Cache.write(test[:set], test[:set][:data])
      end
      if test[:delete]
        Cache.delete(test[:delete][:key])
      end
      if test[:cleanup]
        Cache.clear
      end
      if test[:sleep]
        sleep test[:sleep]
      end
      if test[:verify]
        cache = Cache.get(test[:verify])
        assert_equal(cache, test[:verify][:data], 'verify')
      end
    }
  end

  # verify if second cache write overwrite first one
  test 'cache reset' do
    Cache.write('some_reset_key', 123)
    Cache.write('some_reset_key', 12_356)
    cache = Cache.get('some_reset_key')
    assert_equal(cache, 12_356, 'verify')
  end
end
