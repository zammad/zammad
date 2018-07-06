
require 'test_helper'

class ApiAuthControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create!(
      login: 'api-admin-auth-behalf',
      firstname: 'API',
      lastname: 'Admin',
      email: 'api-admin-auth-behalf@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer = User.create!(
      login: 'api-customer1-auth-behalf@example.com',
      firstname: 'API',
      lastname: 'Customer1',
      email: 'api-customer1-auth-behalf@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

  end

  test 'X-On-Behalf-Of auth - ticket create admin for customer by id' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('api-admin-auth-behalf@example.com', 'adminpw')

    ticket_create_headers = @headers.merge(
      'Authorization' => credentials,
      'X-On-Behalf-Of' => @customer.id,
    )

    params = {
      title: 'a new ticket #3',
      group: 'Users',
      priority: '2 normal',
      state: 'new',
      customer_id: @customer.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: ticket_create_headers
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(result['created_by_id'], @customer.id)
  end

  test 'X-On-Behalf-Of auth - ticket create admin for customer by login' do
    ActivityStream.cleanup(1.year)

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('api-admin-auth-behalf@example.com', 'adminpw')

    ticket_create_headers = @headers.merge(
      'Authorization' => credentials,
      'X-On-Behalf-Of' => @customer.login,
    )
    admin_headers = @headers.merge(
      'Authorization' => credentials,
    )

    params = {
      title: 'a new ticket #3',
      group: 'Users',
      priority: '2 normal',
      state: 'new',
      customer_id: @customer.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: ticket_create_headers
    assert_response(201)
    result_ticket_create = JSON.parse(@response.body)
    assert_equal(Hash, result_ticket_create.class)
    assert_equal(result_ticket_create['created_by_id'], @customer.id)

    get '/api/v1/activity_stream?full=true', params: {}, headers: admin_headers
    assert_response(200)
    result_activity_stream = JSON.parse(@response.body)
    assert_equal(Hash, result_activity_stream.class)

    ticket_created = nil
    result_activity_stream['record_ids'].each do |record_id|
      activity_stream = ActivityStream.find(record_id)
      next if activity_stream.object.name != 'Ticket'
      next if activity_stream.o_id != result_ticket_create['id']
      ticket_created = activity_stream
    end

    assert(ticket_created)
    assert_equal(ticket_created.created_by_id, @customer.id)

    get '/api/v1/activity_stream', params: {}, headers: admin_headers
    assert_response(200)
    result_activity_stream = JSON.parse(@response.body)
    assert_equal(Array, result_activity_stream.class)

    ticket_created = nil
    result_activity_stream.each do |record|
      activity_stream = ActivityStream.find(record['id'])
      next if activity_stream.object.name != 'Ticket'
      next if activity_stream.o_id != result_ticket_create['id']
      ticket_created = activity_stream
    end

    assert(ticket_created)
    assert_equal(ticket_created.created_by_id, @customer.id)

  end

  test 'X-On-Behalf-Of auth - ticket create admin for customer by email' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('api-admin-auth-behalf@example.com', 'adminpw')

    ticket_create_headers = @headers.merge(
      'Authorization' => credentials,
      'X-On-Behalf-Of' => @customer.email,
    )

    params = {
      title: 'a new ticket #3',
      group: 'Users',
      priority: '2 normal',
      state: 'new',
      customer_id: @customer.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: ticket_create_headers
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(result['created_by_id'], @customer.id)
  end

  test 'X-On-Behalf-Of auth - ticket create admin for unknown' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('api-admin-auth-behalf@example.com', 'adminpw')

    ticket_create_headers = @headers.merge(
      'Authorization' => credentials,
      'X-On-Behalf-Of' => 99_449_494_949,
    )

    params = {
      title: 'a new ticket #3',
      group: 'Users',
      priority: '2 normal',
      state: 'new',
      customer_id: @customer.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: ticket_create_headers
    assert_response(401)
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal("No such user '99449494949'", result['error'])
  end

  test 'X-On-Behalf-Of auth - ticket create customer for admin' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('api-customer1-auth-behalf@example.com', 'customer1pw')

    ticket_create_headers = @headers.merge(
      'Authorization' => credentials,
      'X-On-Behalf-Of' => @admin.email,
    )

    params = {
      title: 'a new ticket #3',
      group: 'Users',
      priority: '2 normal',
      state: 'new',
      customer_id: @customer.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: ticket_create_headers
    assert_response(401)
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal("Current user has no permission to use 'X-On-Behalf-Of'!", result['error'])
  end

  test 'X-On-Behalf-Of auth - ticket create admin for customer by email but no permitted action' do
    group_secret = Group.new(name: 'secret1234')
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('api-admin-auth-behalf@example.com', 'adminpw')

    ticket_create_headers = @headers.merge(
      'Authorization' => credentials,
      'X-On-Behalf-Of' => @customer.email,
    )

    params = {
      title: 'a new ticket #3',
      group: group_secret.name,
      priority: '2 normal',
      state: 'new',
      customer_id: @customer.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: ticket_create_headers
    assert_response(422)
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('No lookup value found for \'group\': "secret1234"', result['error'])
  end
end
