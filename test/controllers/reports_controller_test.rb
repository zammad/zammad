require 'test_helper'

class ReportsControllerTest < ActionDispatch::IntegrationTest
  include SearchindexHelper

  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    @year = DateTime.now.utc.year
    @month = DateTime.now.utc.month
    @week = DateTime.now.utc.strftime('%U').to_i
    @day = DateTime.now.utc.day

    roles  = Role.where(name: 'Admin')
    groups = Group.all

    UserInfo.current_user_id = 1

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

    @group1 = Group.create!(
      name: "GroupWithoutPermission-#{rand(9_999_999_999)}",
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    @ticket1 = Ticket.create!(
      title: 'ticket for report',
      group_id: @group1.id,
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'open'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Ticket::Article.create!(
      type: Ticket::Article::Type.lookup(name: 'note'),
      sender: Ticket::Article::Sender.lookup(name: 'Customer'),
      from: 'sender',
      subject: 'subject',
      body: 'some body',
      ticket_id: @ticket1.id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    configure_elasticsearch do

      travel 1.minute

      rebuild_searchindex

      # execute background jobs
      Scheduler.worker(true)

      sleep 6
    end
  end

  test '01.01 report example - admin access' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    get "/api/v1/reports/sets?sheet=true;metric=count;year=#{@year};month=#{@month};week=#{@week};day=#{@day};timeRange=year;profile_id=1;downloadBackendSelected=count::created", params: {}, headers: @headers.merge('Authorization' => credentials)

    assert_response(200)
    assert(@response['Content-Disposition'])
    assert_equal('attachment; filename="tickets--all--Created.xls"', @response['Content-Disposition'])
    assert_equal('application/vnd.ms-excel', @response['Content-Type'])
  end
end
