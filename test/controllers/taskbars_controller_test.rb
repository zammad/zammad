
require 'test_helper'

class TaskbarsControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }
    UserInfo.current_user_id = 1

    # create agent
    roles = Role.where(name: 'Agent')
    groups = Group.all

    @agent = User.create!(
      login: 'taskbar-agent@example.com',
      firstname: 'Taskbar',
      lastname: 'Agent',
      email: 'taskbar-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create!(
      login: 'taskbar-customer1@example.com',
      firstname: 'Taskbar',
      lastname: 'Customer1',
      email: 'taskbar-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

  end

  test 'task ownership' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('taskbar-agent@example.com', 'agentpw')
    params = {
      user_id: @customer_without_org.id,
      client_id: '123',
      key: 'Ticket-5',
      callback: 'TicketZoom',
      state: {
        ticket: {
          owner_id: @agent.id,
        },
        article: {},
      },
      params: {
        ticket_id: 5,
        shown: true,
      },
      prio: 3,
      notify: false,
      active: false,
    }

    post '/api/v1/taskbar', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('123', result['client_id'])
    assert_equal(@agent.id, result['user_id'])
    assert_equal(5, result['params']['ticket_id'])
    assert_equal(true, result['params']['shown'])

    taskbar_id = result['id']
    params[:user_id] = @customer_without_org.id
    params[:params] = {
      ticket_id: 5,
      shown: false,
    }
    put "/api/v1/taskbar/#{taskbar_id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('123', result['client_id'])
    assert_equal(@agent.id, result['user_id'])
    assert_equal(5, result['params']['ticket_id'])
    assert_equal(false, result['params']['shown'])

    # try to access with other user
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('taskbar-customer1@example.com', 'customer1pw')
    params = {
      active: true,
    }
    put "/api/v1/taskbar/#{taskbar_id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not allowed to access this task.', result['error'])

    delete "/api/v1/taskbar/#{taskbar_id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not allowed to access this task.', result['error'])

    # delete with correct user
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('taskbar-agent@example.com', 'agentpw')
    delete "/api/v1/taskbar/#{taskbar_id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result.blank?)
  end

end
