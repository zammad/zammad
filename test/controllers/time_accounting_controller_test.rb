require 'test_helper'
require 'rake'

class TimeAccountingControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    roles  = Role.where(name: 'Admin')
    groups = Group.all

    UserInfo.current_user_id = 1

    @year = DateTime.now.utc.year
    @month = DateTime.now.utc.month

    @admin = User.create!(
      login: 'rest-admin',
      firstname: 'Rest',
      lastname: 'Agent',
      email: 'rest-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1
    )

    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create!(
      login: 'rest-customer1@example.com',
      firstname: 'Rest',
      lastname: 'Customer1',
      email: 'rest-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
      updated_by_id: 1,
      created_by_id: 1
    )
  end

  test '01.01 time account report' do
    group = Group.create!(
      name: "GroupWithoutPermission-#{rand(9_999_999_999)}",
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket = Ticket.create!(
      title: 'ticket for report',
      group_id: group.id,
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'open'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    article = Ticket::Article.create!(
      type: Ticket::Article::Type.lookup(name: 'note'),
      sender: Ticket::Article::Sender.lookup(name: 'Customer'),
      from: 'sender',
      subject: 'subject',
      body: 'some body',
      ticket_id: ticket.id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    Ticket::TimeAccounting.create!(
      ticket_id: ticket.id,
      ticket_article_id: article.id,
      time_unit: 200,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    get "/api/v1/time_accounting/log/by_ticket/#{@year}/#{@month}?download=true", params: {}, headers: @headers.merge('Authorization' => credentials)

    assert_response(200)
    assert(@response['Content-Disposition'])
    assert_equal("attachment; filename=\"by_ticket-#{@year}-#{@month}.xls\"", @response['Content-Disposition'])
    assert_equal('application/vnd.ms-excel', @response['Content-Type'])
  end
end
