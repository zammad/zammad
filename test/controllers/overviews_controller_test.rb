
require 'test_helper'

class OverviewsControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create!(
      login: 'tickets-admin',
      firstname: 'Tickets',
      lastname: 'Admin',
      email: 'tickets-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create agent
    roles = Role.where(name: 'Agent')
    @agent = User.create!(
      login: 'tickets-agent@example.com',
      firstname: 'Tickets',
      lastname: 'Agent',
      email: 'tickets-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: Group.all,
    )

  end

  test 'no permissions' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent', 'agentpw')

    params = {
      name: 'Overview2',
      link: 'my_overview',
      roles: Role.where(name: 'Agent').pluck(:name),
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    }

    post '/api/v1/overviews', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('authentication failed', result['error'])
  end

  test 'create overviews' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')

    params = {
      name: 'Overview2',
      link: 'my_overview',
      roles: Role.where(name: 'Agent').pluck(:name),
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    }

    post '/api/v1/overviews', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Overview2', result['name'])
    assert_equal('my_overview', result['link'])

    post '/api/v1/overviews', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Overview2', result['name'])
    assert_equal('my_overview_1', result['link'])
  end

  test 'set mass prio' do
    roles = Role.where(name: 'Agent')
    overview1 = Overview.create!(
      name: 'Overview1',
      link: 'my_overview',
      roles: roles,
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
      prio: 1,
      updated_by_id: 1,
      created_by_id: 1,
    )
    overview2 = Overview.create!(
      name: 'Overview2',
      link: 'my_overview',
      roles: roles,
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
      prio: 2,
      updated_by_id: 1,
      created_by_id: 1,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')
    params = {
      prios: [
        [overview2.id, 1],
        [overview1.id, 2],
      ]
    }
    post '/api/v1/overviews_prio', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(true, result['success'])

    overview1.reload
    overview2.reload

    assert_equal(2, overview1.prio)
    assert_equal(1, overview2.prio)
  end

  test 'create an overview with group_by direction' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')

    params = {
      name: 'Overview2',
      link: 'my_overview',
      roles: Role.where(name: 'Agent').pluck(:name),
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      group_by: 'priority',
      group_direction: 'ASC',
      view: {
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    }

    post '/api/v1/overviews', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Overview2', result['name'])
    assert_equal('my_overview', result['link'])
    assert_equal('priority', result['group_by'])
    assert_equal('ASC', result['group_direction'])
  end

end
