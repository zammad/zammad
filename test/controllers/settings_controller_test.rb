# encoding: utf-8
require 'test_helper'

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w(Admin Agent))
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create_or_update(
      login: 'setting-admin',
      firstname: 'Setting',
      lastname: 'Admin',
      email: 'setting-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create agent
    roles = Role.where(name: 'Agent')
    @agent = User.create_or_update(
      login: 'setting-agent@example.com',
      firstname: 'Setting',
      lastname: 'Agent',
      email: 'setting-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create_or_update(
      login: 'setting-customer1@example.com',
      firstname: 'Setting',
      lastname: 'Customer1',
      email: 'setting-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

  end

  test 'settings index with nobody' do

    # index
    get '/api/v1/settings', {}, @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['settings'])
  end

  test 'settings index with admin' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('setting-admin@example.com', 'adminpw')

    # index
    get '/api/v1/settings', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)
  end

  test 'settings index with agent' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('setting-agent@example.com', 'agentpw')

    # index
    get '/api/v1/settings', {}, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['settings'])
    assert_equal('No permission (user)!', result['error'])
  end

  test 'settings index with customer' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('setting-customer1@example.com', 'customer1pw')

    # index
    get '/api/v1/settings', {}, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['settings'])
    assert_equal('No permission (user)!', result['error'])
  end

end
