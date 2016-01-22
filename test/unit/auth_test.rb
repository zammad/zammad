# encoding: utf-8
require 'test_helper'

# set config
if !ENV['LDAP_HOST']
  fail "ERROR: Need LDAP_HOST - hint LDAP_HOST='ldap://ci.zammad.org'"
end

Setting.create_or_update(
  title: 'Authentication via LDAP',
  name: 'auth_ldap',
  area: 'Security::Authentication',
  description: 'Enables user authentication via LDAP.',
  state: {
    adapter: 'Auth::Ldap',
    host: ENV['LDAP_HOST'],
    port: 389,
    bind_dn: 'cn=Manager,dc=example,dc=org',
    bind_pw: 'example',
    uid: 'mail',
    base: 'dc=example,dc=org',
    always_filter: '',
    always_roles: %w(Admin Agent),
    always_groups: ['Users'],
    sync_params: {
      firstname: 'sn',
      lastname: 'givenName',
      email: 'mail',
      login: 'mail',
    },
  },
  frontend: false
)

user = User.lookup(email: 'nicole.braun@zammad.org')
if user
  user.update_attributes(
    login: 'nicole.braun',
    password: 'some_pass',
    active: true,
  )
else
  User.create_if_not_exists(
    login: 'nicole.braun',
    firstname: 'Nicole',
    lastname: 'Braun',
    email: 'nicole.braun@zammad.org',
    password: 'some_pass',
    active: true,
    updated_by_id: 1,
    created_by_id: 1
  )
end

class AuthTest < ActiveSupport::TestCase
  test 'auth' do
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

      # test 5
      {
        username: 'paige.chen@example.org',
        password: 'password',
        result: true,
        verify: {
          firstname: 'Chen',
          lastname: 'Paige',
          email: 'paige.chen@example.org',
        }
      },

    ]
    tests.each { |test|
      user = User.authenticate(test[:username], test[:password])
      if test[:result] == true
        if !user
          assert(false, 'auth faild')
        else
          test[:verify].each {|key, value|
            assert_equal(user[key], value, 'verify')
          }
        end
      else
        assert_equal(test[:result], user, 'faild or not existing')
      end
    }
  end
end
