
require 'test_helper'

class SlaControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create!(
      login: 'sla-admin',
      firstname: 'Packages',
      lastname: 'Admin',
      email: 'sla-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

  end

  test '01 sla index with nobody' do

    get '/api/v1/slas', params: {}, headers: @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('authentication failed', result['error'])

  end

  test '02 sla index with admin' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('sla-admin@example.com', 'adminpw')

    get '/api/v1/slas', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)
    assert_equal(0, result.count)

    get '/api/v1/slas?expand=true', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)
    assert_equal(0, result.count)

    get '/api/v1/slas?full=true', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
    assert(result['record_ids'])
    assert(result['record_ids'].blank?)
    assert(result['assets'])
    assert(result['assets']['Calendar'].present?)
    assert(result['assets'].present?)

  end

end
