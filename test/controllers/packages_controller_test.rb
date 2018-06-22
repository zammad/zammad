
require 'test_helper'

class PackagesControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create!(
      login: 'packages-admin',
      firstname: 'Packages',
      lastname: 'Admin',
      email: 'packages-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create agent
    roles = Role.where(name: 'Agent')
    @agent = User.create!(
      login: 'packages-agent@example.com',
      firstname: 'Rest',
      lastname: 'Agent',
      email: 'packages-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create!(
      login: 'packages-customer1@example.com',
      firstname: 'Packages',
      lastname: 'Customer1',
      email: 'packages-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

  end

  test '01 packages index with nobody' do

    # index
    get '/api/v1/packages', params: {}, headers: @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['packages'])
    assert_equal('authentication failed', result['error'])
  end

  test '02 packages index with admin' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('packages-admin@example.com', 'adminpw')

    # index
    get '/api/v1/packages', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['packages'])
  end

  test '03 packages index with admin and wrong pw' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('packages-admin@example.com', 'wrongadminpw')

    # index
    get '/api/v1/packages', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('authentication failed', result['error'])
  end

  test '04 packages index with inactive admin' do
    @admin.active = false
    @admin.save!

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('packages-admin@example.com', 'adminpw')

    # index
    get '/api/v1/packages', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('authentication failed', result['error'])
  end

  test '05 packages index with agent' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('packages-agent@example.com', 'agentpw')

    # index
    get '/api/v1/packages', params: {}, headers: @headers.merge('Authorization' => credentials)

    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['packages'])
    assert_equal('Not authorized (user)!', result['error'])
  end

  test '06 packages index with customer' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('packages-customer1@example.com', 'customer1pw')

    # index
    get '/api/v1/packages', params: {}, headers: @headers.merge('Authorization' => credentials)

    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['packages'])
    assert_equal('Not authorized (user)!', result['error'])
  end

end
