
require 'test_helper'

class TicketsControllerEscalationTest < ActionDispatch::IntegrationTest
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
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create!(
      login: 'tickets-customer1@example.com',
      firstname: 'Tickets',
      lastname: 'Customer1',
      email: 'tickets-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

    @calendar = Calendar.create!(
      name: 'Escalation Test',
      timezone: 'Europe/Berlin',
      business_hours: {
        mon: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        tue: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        wed: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        thu: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        fri: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        sat: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        sun: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
      },
      default: true,
      ical_url: nil,
    )

    @sla = Sla.create!(
      name: 'test sla 1',
      condition: {
        'ticket.title' => {
          operator: 'contains',
          value: 'some value 123',
        },
      },
      first_response_time: 60,
      update_time: 180,
      solution_time: 240,
      calendar_id: @calendar.id,
    )

    UserInfo.current_user_id = nil

  end

  test '01.01 ticket created via web' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')
    params = {
      title: 'some value 123',
      group: 'Users',
      article: {
        body: 'some test 123',
      },
    }

    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('some value 123', result['title'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(@customer_without_org.id, result['created_by_id'])

    ticket_p = Ticket.find(result['id'])

    assert_equal(ticket_p['escalation_at'].iso8601, result['escalation_at'].sub(/.\d\d\dZ$/, 'Z'))
    assert_equal(ticket_p['first_response_escalation_at'].iso8601, result['first_response_escalation_at'].sub(/.\d\d\dZ$/, 'Z'))
    assert_equal(ticket_p['update_escalation_at'].iso8601, result['update_escalation_at'].sub(/.\d\d\dZ$/, 'Z'))
    assert_equal(ticket_p['close_escalation_at'].iso8601, result['close_escalation_at'].sub(/.\d\d\dZ$/, 'Z'))

    assert(ticket_p.escalation_at)
    assert_in_delta(ticket_p.first_response_escalation_at.to_i, (ticket_p.created_at + 1.hour).to_i, 90)
    assert_in_delta(ticket_p.update_escalation_at.to_i, (ticket_p.created_at + 3.hours).to_i, 90)
    assert_in_delta(ticket_p.close_escalation_at.to_i, (ticket_p.created_at + 4.hours).to_i, 90)
    assert_in_delta(ticket_p.escalation_at.to_i, (ticket_p.created_at + 1.hour).to_i, 90)
  end

  test '01.02 ticket got created via email - reply by agent via web' do

    email = "From: Bob Smith <customer@example.com>
To: zammad@example.com
Subject: some value 123

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email)
    ticket_p.reload
    assert(ticket_p.escalation_at)
    assert_in_delta(ticket_p.first_response_escalation_at.to_i, (ticket_p.created_at + 1.hour).to_i, 90)
    assert_in_delta(ticket_p.update_escalation_at.to_i, (ticket_p.created_at + 3.hours).to_i, 90)
    assert_in_delta(ticket_p.close_escalation_at.to_i, (ticket_p.created_at + 4.hours).to_i, 90)
    assert_in_delta(ticket_p.escalation_at.to_i, (ticket_p.created_at + 1.hour).to_i, 90)

    travel 3.hours

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'some value 123 - update',
      article: {
        body: 'some test 123',
        type: 'email',
        to: 'customer@example.com',
      },
    }
    put "/api/v1/tickets/#{ticket_p.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)

    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'open').id, result['state_id'])
    assert_equal('some value 123 - update', result['title'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(user_p.id, result['created_by_id'])

    ticket_p.reload
    assert_equal(ticket_p['escalation_at'].iso8601, result['escalation_at'].sub(/.\d\d\dZ$/, 'Z'))
    assert_equal(ticket_p['first_response_escalation_at'].iso8601, result['first_response_escalation_at'].sub(/.\d\d\dZ$/, 'Z'))
    assert_equal(ticket_p['update_escalation_at'].iso8601, result['update_escalation_at'].sub(/.\d\d\dZ$/, 'Z'))
    assert_equal(ticket_p['close_escalation_at'].iso8601, result['close_escalation_at'].sub(/.\d\d\dZ$/, 'Z'))

    assert_in_delta(ticket_p.first_response_escalation_at.to_i, (ticket_p.created_at + 1.hour).to_i, 90)
    assert_in_delta(ticket_p.update_escalation_at.to_i, (ticket_p.last_contact_agent_at + 3.hours).to_i, 90)
    assert_in_delta(ticket_p.close_escalation_at.to_i, (ticket_p.created_at + 4.hours).to_i, 90)
    assert_in_delta(ticket_p.escalation_at.to_i, (ticket_p.created_at + 4.hours).to_i, 90)

  end

end
