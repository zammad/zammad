# encoding: utf-8
# rubocop:disable Next
require 'test_helper'

class TokenTest < ActiveSupport::TestCase
  test 'token' do

    tests = [

      # test 1
      {
        test_name: 'invalid token',
        action: 'PasswordReset',
        name: '1NV4L1D',
        result: nil,
      },

      # test 2
      {
        test_name: 'fresh token',
        create: {
          user_id: 2,
          action: 'PasswordReset',
        },
        action: 'PasswordReset',
        result: true,
        verify: {
          firstname: 'Nicole',
          lastname: 'Braun',
          email: 'nicole.braun@zammad.org',
        }
      },

      # test 3
      {
        test_name: 'two days but not persistent',
        create: {
          user_id: 2,
          action: 'PasswordReset',
          created_at: 2.days.ago,
        },
        action: 'PasswordReset',
        result: nil,
      },

      {
        test_name: 'two days but persistent',
        create: {
          user_id: 2,
          action: 'iCal',
          created_at: 2.days.ago,
          persistent: true,
        },
        action: 'iCal',
        result: true,
        verify: {
          firstname: 'Nicole',
          lastname: 'Braun',
          email: 'nicole.braun@zammad.org',
        }
      },
    ]

    tests.each { |test|

      if test[:create]

        #puts test[:test_name] + ': creating token '+ test[:create].inspect

        token = Token.create(
          action: test[:create][:action],
          user_id: test[:create][:user_id],
          created_at: test[:create][:created_at].to_s,
          persistent: test[:create][:persistent]
        )

        #puts test[:test_name] + ': created token ' + token.inspect

        test[:name] = token.name
      end

      user = Token.check(
        action: test[:action],
        name: test[:name]
      )

      if test[:result] == true
        if !user
          assert( false, test[:test_name] + ': token verification failed' )
        else
          test[:verify].each { |key, value|
            assert_equal( user[key], value, 'verify' )
          }
        end
      else
        assert_equal( test[:result], user, test[:test_name] + ': failed or not existing' )
      end

      if test[:name]
        #puts test[:test_name] + ': deleting token '+ test[:name]

        token = Token.where( name: test[:name] ).first

        if token
          token.destroy
        end
      end
    }
  end
end
