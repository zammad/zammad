# encoding: utf-8
require 'test_helper'

class TicketsControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w(Admin Agent))
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create_or_update(
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
    @agent = User.create_or_update(
      login: 'tickets-agent@example.com',
      firstname: 'Tickets',
      lastname: 'Agent',
      email: 'tickets-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create_or_update(
      login: 'tickets-customer1@example.com',
      firstname: 'Tickets',
      lastname: 'Customer1',
      email: 'tickets-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

  end

  test '01 ticket create with agent' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')

    params = {
      title: 'a new ticket #1',
      state: 'new',
      priority: '2 normal',
      group: 'Users',
      customer: 'tickets-customer1@example.com',
      article: {
        content_type: 'text/plain', # or text/html
        body: 'some body',
        sender: 'Customer',
        type: 'note',
      },
      links: {
        Ticket: {
          parent: [1],
        }
      }
    }

    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)

    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #1', result['title'])

    links = Link.list(
      link_object: 'Ticket',
      link_object_value: result['id'],
    )
    p links.inspect
  end

end
