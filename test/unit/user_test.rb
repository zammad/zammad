# encoding: utf-8
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'user' do
    tests = [
      {
        name: '#1 - simple create',
        create: {
          firstname: 'Firstname',
          lastname: 'Lastname',
          email: 'some@example.com',
          login: 'some@example.com',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname: 'Lastname',
          image: nil,
          fullname: 'Firstname Lastname',
          email: 'some@example.com',
          login: 'some@example.com',
        },
      },
      {
        name: '#2 - simple create - no lastname',
        create: {
          firstname: 'Firstname Lastname',
          lastname: '',
          email: 'some@example.com',
          login: 'some@example.com',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname: 'Lastname',
          image: nil,
          email: 'some@example.com',
          login: 'some@example.com',
        },
      },
      {
        name: '#3 - simple create - nil as lastname',
        create: {
          firstname: 'Firstname Lastname',
          lastname: '',
          email: 'some@example.com',
          login: 'some@example.com',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname: 'Lastname',
          image: nil,
          email: 'some@example.com',
          login: 'some@example.com',
        },
      },
      {
        name: '#4 - simple create - no lastname, firstname with ","',
        create: {
          firstname: 'Lastname, Firstname',
          lastname: '',
          email: 'some@example.com',
          login: 'some@example.com',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname: 'Lastname',
          email: 'some@example.com',
          login: 'some@example.com',
        },
      },
      {
        name: '#5 - simple create - no lastname/firstname',
        create: {
          firstname: '',
          lastname: '',
          email: 'firstname.lastname@example.com',
          login: 'login-1',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname: 'Lastname',
          fullname: 'Firstname Lastname',
          email: 'firstname.lastname@example.com',
          login: 'login-1',
        },
      },
      {
        name: '#6 - simple create - no lastname/firstnam',
        create: {
          firstname: '',
          lastname: '',
          email: 'FIRSTNAME.lastname@example.com',
          login: 'login-2',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname: 'Lastname',
          email: 'firstname.lastname@example.com',
          login: 'login-2',
        },
      },
      {
        name: '#7 - simple create - nill as fristname and lastname',
        create: {
          firstname: '',
          lastname: '',
          email: 'FIRSTNAME.lastname@example.com',
          login: 'login-3',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname: 'Lastname',
          email: 'firstname.lastname@example.com',
          login: 'login-3',
        },
      },
      {
        name: '#8 - update with avatar check',
        create: {
          firstname: 'Bob',
          lastname: 'Smith',
          email: 'bob.smith@example.com',
          login: 'login-4',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Bob',
          lastname: 'Smith',
          image: nil,
          email: 'bob.smith@example.com',
          login: 'login-4',
        },
        update: {
          email: 'unit-test1@znuny.com',
        },
        update_verify: {
          firstname: 'Bob',
          lastname: 'Smith',
          image: 'a6f7f7f9dac25b2c023d403ef998801c',
          image_md5: 'a6f7f7f9dac25b2c023d403ef998801c',
          email: 'unit-test1@znuny.com',
          login: 'login-4',
        }
      },
      {
        name: '#9 - update create with avatar check',
        create: {
          firstname: 'Bob',
          lastname: 'Smith',
          email: 'unit-test2@znuny.com',
          login: 'login-5',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Bob',
          lastname: 'Smith',
          image: '8765a1ac93f54405d8dfdd856c48c31f',
          image_md5: '8765a1ac93f54405d8dfdd856c48c31f',
          email: 'unit-test2@znuny.com',
          login: 'login-5',
        },
        update: {
          email: 'unit-test1@znuny.com',
        },
        update_verify: {
          firstname: 'Bob',
          lastname: 'Smith',
          image: 'a6f7f7f9dac25b2c023d403ef998801c',
          image_md5: 'a6f7f7f9dac25b2c023d403ef998801c',
          email: 'unit-test1@znuny.com',
          login: 'login-5',
        }
      },
      {
        name: '#10 - update create with login/email check',
        create: {
          firstname: '',
          lastname: '',
          email: 'caoyaoewfzfw@21222cn.com',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: '',
          lastname: '',
          fullname: 'caoyaoewfzfw@21222cn.com',
          email: 'caoyaoewfzfw@21222cn.com',
          login: 'caoyaoewfzfw@21222cn.com',
        },
        update: {
          email: 'caoyaoewfzfw@212224cn.com',
        },
        update_verify: {
          firstname: '',
          lastname: '',
          email: 'caoyaoewfzfw@212224cn.com',
          fullname: 'caoyaoewfzfw@212224cn.com',
          login: 'caoyaoewfzfw@212224cn.com',
        }
      },
      {
        name: '#11 - update create with login/email check',
        create: {
          firstname: 'Firstname',
          lastname: 'Lastname',
          email: 'some_tEst11@example.com',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname: 'Lastname',
          fullname: 'Firstname Lastname',
          email: 'some_test11@example.com',
        },
        update: {
          email: 'some_Test11-1@example.com',
        },
        update_verify: {
          firstname: 'Firstname',
          lastname: 'Lastname',
          email: 'some_test11-1@example.com',
          fullname: 'Firstname Lastname',
          login: 'some_test11-1@example.com',
        }
      },
    ]

    tests.each { |test|

      # check if user exists
      user = User.where( login: test[:create][:login] ).first
      if user
        user.destroy
      end

      user = User.create( test[:create] )

      test[:create_verify].each { |key, value|
        next if key == :image_md5
        if user.respond_to?( key )
          assert_equal( value, user.send(key), "create check #{key} in (#{test[:name]})"  )
        else
          assert_equal( value, user[key], "create check #{key} in (#{test[:name]})" )
        end
      }
      if test[:create_verify][:image_md5]
        file = Avatar.get_by_hash( user.image )
        file_md5 = Digest::MD5.hexdigest( file.content )
        assert_equal( test[:create_verify][:image_md5], file_md5, "create avatar md5 check in (#{test[:name]})"  )
      end
      if test[:update]
        user.update_attributes( test[:update] )

        test[:update_verify].each { |key, value|
          next if key == :image_md5
          if user.respond_to?( key )
            assert_equal( value, user.send(key), "update check #{key} in (#{test[:name]})"  )
          else
            assert_equal( value, user[key], "update check #{key} in (#{test[:name]})"  )
          end
        }

        if test[:update_verify][:image_md5]
          file = Avatar.get_by_hash( user.image )
          file_md5 = Digest::MD5.hexdigest( file.content )
          assert_equal( test[:update_verify][:image_md5], file_md5, "update avatar md5 check in (#{test[:name]})"  )
        end
      end

      user.destroy
    }
  end

  test 'user default preferences' do
    groups = Group.where(name: 'Users')
    roles  = Role.where(name: 'Agent')
    agent1 = User.create_or_update(
      login: 'agent-default-preferences1@example.com',
      firstname: 'Preferences',
      lastname: 'Agent1',
      email: 'agent-default-preferences1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      preferences: {
        locale: 'de-de',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(agent1.preferences)
    assert(agent1.preferences['locale'])
    assert_equal(agent1.preferences['locale'], 'de-de')
    assert(agent1.preferences['notification_config'])
    assert(agent1.preferences['notification_config']['matrix'])
    assert(agent1.preferences['notification_config']['matrix']['create'])
    assert(agent1.preferences['notification_config']['matrix']['update'])

    roles = Role.where(name: 'Customer')
    customer1 = User.create_or_update(
      login: 'customer-default-preferences1@example.com',
      firstname: 'Preferences',
      lastname: 'Customer1',
      email: 'customer-default-preferences1@example.com',
      password: 'customerpw',
      active: true,
      roles: roles,
      preferences: {
        locale: 'de-de',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer1.preferences)
    assert(customer1.preferences['locale'])
    assert_equal(customer1.preferences['locale'], 'de-de')
    assert_not(customer1.preferences['notification_config'])

    customer1.roles = Role.where(name: 'Agent')
    assert(customer1.preferences)
    assert(customer1.preferences['locale'])
    assert_equal(customer1.preferences['locale'], 'de-de')
    assert(customer1.preferences['notification_config'])
    assert(customer1.preferences['notification_config']['matrix']['create'])
    assert(customer1.preferences['notification_config']['matrix']['update'])

  end

end
