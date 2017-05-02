# encoding: utf-8
require 'test_helper'

class AuthTest < ActiveSupport::TestCase
  test 'auth' do

    user = User.find_by(email: 'nicole.braun@zammad.org')
    user.update_attributes(
      login: 'nicole.braun',
      firstname: 'Nicole',
      lastname: 'Braun',
      email: 'nicole.braun@zammad.org',
      password: 'some_pass',
      active: true,
      updated_by_id: 1,
      created_by_id: 1
    )

    tests = [

      # test 1
      {
        username: 'not_existing',
        password: 'password',
        result: nil,
      },

      # test 2
      {
        username: 'nicole.braun@zammad.org',
        password: 'some_pass',
        result: true,
        verify: {
          firstname: 'Nicole',
          lastname: 'Braun',
          email: 'nicole.braun@zammad.org',
        }
      },

      # test 3
      {
        username: 'nicole.bRaUn@zammad.org',
        password: 'some_pass',
        result: true,
        verify: {
          firstname: 'Nicole',
          lastname: 'Braun',
          email: 'nicole.braun@zammad.org',
        }
      },

      # test 4
      {
        username: 'nicole.bRaUn',
        password: 'some_pass',
        result: true,
        verify: {
          firstname: 'Nicole',
          lastname: 'Braun',
          email: 'nicole.braun@zammad.org',
        }
      },

    ]
    tests.each { |test|
      user = User.authenticate(test[:username], test[:password])
      if test[:result] == true
        if !user
          assert(false, 'auth failed')
        else
          test[:verify].each { |key, value|
            assert_equal(user[key], value, 'verify')
          }
        end
      elsif test[:result].nil?
        assert_nil(user, 'failed or not existing')
      else
        assert_equal(test[:result], user, 'failed or not existing')
      end
    }
  end
end
