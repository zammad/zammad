# encoding: utf-8
require 'test_helper'

class AssetsTest < ActiveSupport::TestCase
  test 'user' do

    roles  = Role.where(name: %w(Agent Admin))
    groups = Group.all
    org1   = Organization.create_or_update(
      name: 'some user org',
      updated_by_id: 1,
      created_by_id: 1,
    )

    user1 = User.create_or_update(
      login: 'assets1@example.org',
      firstname: 'assets1',
      lastname: 'assets1',
      email: 'assets1@example.org',
      password: 'some_pass',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
      organization_id: org1.id,
      roles: roles,
      groups: groups,
    )

    user2 = User.create_or_update(
      login: 'assets2@example.org',
      firstname: 'assets2',
      lastname: 'assets2',
      email: 'assets2@example.org',
      password: 'some_pass',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
      roles: roles,
      groups: groups,
    )

    user3 = User.create_or_update(
      login: 'assets3@example.org',
      firstname: 'assets3',
      lastname: 'assets3',
      email: 'assets3@example.org',
      password: 'some_pass',
      active: true,
      updated_by_id: user1.id,
      created_by_id: user2.id,
      roles: roles,
      groups: groups,
    )
    user3 = User.find(user3.id)
    assets = user3.assets({})

    org1 = Organization.find(org1.id)
    attributes = org1.attributes_with_association_ids
    attributes.delete('user_ids')
    assert( diff(attributes, assets[:Organization][org1.id]), 'check assets')

    user1 = User.find(user1.id)
    attributes = user1.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user1.id]), 'check assets' )

    user2 = User.find(user2.id)
    attributes = user2.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user2.id]), 'check assets' )

    user3 = User.find(user3.id)
    attributes = user3.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user3.id]), 'check assets' )

    # touch org, check if user1 has changed
    travel 2.seconds
    org2 = Organization.find(org1.id)
    org2.note = "some note...#{rand(9_999_999_999_999)}"
    org2.save!

    attributes = org2.attributes_with_association_ids
    attributes.delete('user_ids')
    assert( !diff(attributes, assets[:Organization][org2.id]), 'check assets' )

    user1_new = User.find(user1.id)
    attributes = user1_new.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( !diff(attributes, assets[:User][user1_new.id]), 'check assets' )

    # check new assets lookup
    assets = user3.assets({})
    attributes = org2.attributes_with_association_ids
    attributes.delete('user_ids')
    assert( diff(attributes, assets[:Organization][org1.id]), 'check assets')

    user1 = User.find(user1.id)
    attributes = user1.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user1.id]), 'check assets' )

    user2 = User.find(user2.id)
    attributes = user2.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user2.id]), 'check assets' )

    user3 = User.find(user3.id)
    attributes = user3.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user3.id]), 'check assets' )
    travel_back

    user3.destroy!
    user2.destroy!
    user1.destroy!
    org1.destroy!
    assert_not(Organization.find_by(id: org2.id))
  end

  test 'organization' do

    roles  = Role.where( name: %w(Agent Admin) )
    admin1 = User.create_or_update(
      login: 'admin1@example.org',
      firstname: 'admin1',
      lastname: 'admin1',
      email: 'admin1@example.org',
      password: 'some_pass',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
      roles: roles,
    )

    roles = Role.where( name: %w(Customer) )
    org   = Organization.create_or_update(
      name: 'some customer org',
      updated_by_id: admin1.id,
      created_by_id: 1,
    )

    user1 = User.create_or_update(
      login: 'assets1@example.org',
      firstname: 'assets1',
      lastname: 'assets1',
      email: 'assets1@example.org',
      password: 'some_pass',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
      organization_id: org.id,
      roles: roles,
    )

    user2 = User.create_or_update(
      login: 'assets2@example.org',
      firstname: 'assets2',
      lastname: 'assets2',
      email: 'assets2@example.org',
      password: 'some_pass',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
      organization_id: org.id,
      roles: roles,
    )

    user3 = User.create_or_update(
      login: 'assets3@example.org',
      firstname: 'assets3',
      lastname: 'assets3',
      email: 'assets3@example.org',
      password: 'some_pass',
      active: true,
      updated_by_id: user1.id,
      created_by_id: user2.id,
      roles: roles,
    )

    org = Organization.find(org.id)
    assets = org.assets({})
    attributes = org.attributes_with_association_ids
    attributes.delete('user_ids')
    assert( diff(attributes, assets[:Organization][org.id]), 'check assets' )

    admin1 = User.find(admin1.id)
    attributes = admin1.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][admin1.id]), 'check assets' )

    user1 = User.find(user1.id)
    attributes = user1.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user1.id]), 'check assets' )

    user2 = User.find(user2.id)
    attributes = user2.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user2.id]), 'check assets' )

    user3 = User.find(user3.id)
    attributes = user3.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert_nil( assets[:User][user3.id], 'check assets' )

    # touch user 2, check if org has changed
    travel 2.seconds
    user_new_2 = User.find(user2.id)
    user_new_2.lastname = 'assets2'
    user_new_2.save!

    org_new = Organization.find(org.id)
    attributes = org_new.attributes_with_association_ids
    attributes.delete('user_ids')
    assert( !diff(attributes, assets[:Organization][org_new.id]), 'check assets' )

    attributes = user_new_2.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user_new_2.id]), 'check assets' )

    # check new assets lookup
    assets = org_new.assets({})
    attributes = org_new.attributes_with_association_ids
    attributes.delete('user_ids')
    assert( diff(attributes, assets[:Organization][org_new.id]), 'check assets' )

    attributes = user_new_2.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user_new_2.id]), 'check assets' )
    travel_back

    user3.destroy!
    user2.destroy!
    user1.destroy!
    org.destroy!
    assert_not(Organization.find_by(id: org_new.id))
  end

  def diff(o1, o2)
    return true if o1 == o2
    %w(updated_at created_at).each do |item|
      if o1[item]
        o1[item] = o1[item].to_s
      end
      if o2[item]
        o2[item] = o2[item].to_s
      end
    end
    return true if (o1.to_a - o2.to_a).empty?
    #puts "ERROR: difference \n1: #{o1.inspect}\n2: #{o2.inspect}\ndiff: #{(o1.to_a - o2.to_a).inspect}"
    false
  end

  test 'overview' do

    UserInfo.current_user_id = 1
    roles = Role.where(name: %w(Customer))

    user1 = User.create_or_update(
      login: 'assets_overview1@example.org',
      firstname: 'assets_overview1',
      lastname: 'assets_overview1',
      email: 'assets_overview1@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user2 = User.create_or_update(
      login: 'assets_overview2@example.org',
      firstname: 'assets_overview2',
      lastname: 'assets_overview2',
      email: 'assets_overview2@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user3 = User.create_or_update(
      login: 'assets_overview3@example.org',
      firstname: 'assets_overview3',
      lastname: 'assets_overview3',
      email: 'assets_overview3@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user4 = User.create_or_update(
      login: 'assets_overview4@example.org',
      firstname: 'assets_overview4',
      lastname: 'assets_overview4',
      email: 'assets_overview4@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user5 = User.create_or_update(
      login: 'assets_overview5@example.org',
      firstname: 'assets_overview5',
      lastname: 'assets_overview5',
      email: 'assets_overview5@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )

    ticket_state1 = Ticket::State.find_by(name: 'new')
    ticket_state2 = Ticket::State.find_by(name: 'open')
    overview_role = Role.find_by(name: 'Agent')
    overview = Overview.create_or_update(
      name: 'my asset test',
      link: 'my_asset_test',
      prio: 1000,
      role_ids: [overview_role.id],
      user_ids: [user4.id, user5.id],
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [ ticket_state1.id, ticket_state2.id ],
        },
        'ticket.owner_id' => {
          operator: 'is',
          pre_condition: 'specific',
          value: user1.id,
          value_completion: 'John Smith <john.smith@example.com>'
        },
      },
      order: {
        by: 'created_at',
        direction: 'ASC',
      },
      view: {
        d: %w(title customer group created_at),
        s: %w(title customer group created_at),
        m: %w(number title customer group created_at),
        view_mode_default: 's',
      },
    )
    assets = overview.assets({})
    assert(assets[:User][user1.id], 'check assets')
    assert_not(assets[:User][user2.id], 'check assets')
    assert_not(assets[:User][user3.id], 'check assets')
    assert(assets[:User][user4.id], 'check assets')
    assert(assets[:User][user5.id], 'check assets')
    assert(assets[:TicketState][ticket_state1.id], 'check assets')
    assert(assets[:TicketState][ticket_state2.id], 'check assets')

    overview = Overview.create_or_update(
      name: 'my asset test',
      link: 'my_asset_test',
      prio: 1000,
      role_ids: [overview_role.id],
      user_ids: [user4.id],
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: ticket_state1.id,
        },
        'ticket.owner_id' => {
          operator: 'is',
          pre_condition: 'specific',
          value: [user1.id, user2.id],
        },
      },
      order: {
        by: 'created_at',
        direction: 'ASC',
      },
      view: {
        d: %w(title customer group created_at),
        s: %w(title customer group created_at),
        m: %w(number title customer group created_at),
        view_mode_default: 's',
      },
    )
    assets = overview.assets({})
    assert(assets[:User][user1.id], 'check assets')
    assert(assets[:User][user2.id], 'check assets')
    assert_not(assets[:User][user3.id], 'check assets')
    assert(assets[:User][user4.id], 'check assets')
    assert_not(assets[:User][user5.id], 'check assets')
    assert(assets[:TicketState][ticket_state1.id], 'check assets')
    assert_not(assets[:TicketState][ticket_state2.id], 'check assets')
    overview.destroy!
  end

  test 'sla' do

    UserInfo.current_user_id = 1
    roles = Role.where(name: %w(Customer))

    user1 = User.create_or_update(
      login: 'assets_sla1@example.org',
      firstname: 'assets_sla1',
      lastname: 'assets_sla1',
      email: 'assets_sla1@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user2 = User.create_or_update(
      login: 'assets_sla2@example.org',
      firstname: 'assets_sla2',
      lastname: 'assets_sla2',
      email: 'assets_sla2@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )

    calendar1 = Calendar.create_or_update(
      name: 'US 1',
      timezone: 'America/Los_Angeles',
      business_hours: {
        mon: { '09:00' => '17:00' },
        tue: { '09:00' => '17:00' },
        wed: { '09:00' => '17:00' },
        thu: { '09:00' => '17:00' },
        fri: { '09:00' => '17:00' }
      },
      default: true,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket_state1 = Ticket::State.find_by(name: 'new')
    ticket_state2 = Ticket::State.find_by(name: 'open')
    sla = Sla.create_or_update(
      name: 'my asset test',
      calendar_id: calendar1.id,
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [ ticket_state1.id, ticket_state2.id ],
        },
        'ticket.owner_id' => {
          operator: 'is',
          pre_condition: 'specific',
          value: user1.id,
          value_completion: 'John Smith <john.smith@example.com>'
        },
      },
    )
    assets = sla.assets({})
    assert(assets[:User][user1.id], 'check assets')
    assert_not(assets[:User][user2.id], 'check assets')
    assert(assets[:TicketState][ticket_state1.id], 'check assets')
    assert(assets[:TicketState][ticket_state2.id], 'check assets')
    assert(assets[:Calendar][calendar1.id], 'check assets')

  end

  test 'job' do

    UserInfo.current_user_id = 1
    roles = Role.where(name: %w(Customer))

    user1 = User.create_or_update(
      login: 'assets_job1@example.org',
      firstname: 'assets_job1',
      lastname: 'assets_job1',
      email: 'assets_job1@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user2 = User.create_or_update(
      login: 'assets_job2@example.org',
      firstname: 'assets_job2',
      lastname: 'assets_job2',
      email: 'assets_job2@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user3 = User.create_or_update(
      login: 'assets_job3@example.org',
      firstname: 'assets_job3',
      lastname: 'assets_job3',
      email: 'assets_job3@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )

    ticket_state1 = Ticket::State.find_by(name: 'new')
    ticket_state2 = Ticket::State.find_by(name: 'open')
    ticket_priority2 = Ticket::Priority.find_by(name: '2 normal')
    job = Job.create_or_update(
      name: 'my job',
      timeplan: {
        mon: true,
      },
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [ ticket_state1.id, ticket_state2.id ],
        },
        'ticket.owner_id' => {
          operator: 'is',
          pre_condition: 'specific',
          value: user1.id,
          value_completion: 'John Smith <john.smith@example.com>'
        },
      },
      perform: {
        'ticket.priority_id' => {
          value: ticket_priority2.id,
        },
        'ticket.owner_id' => {
          pre_condition: 'specific',
          value: user2.id,
          value_completion: 'metest123@znuny.com <metest123@znuny.com>'
        },
      },
      disable_notification: true,
    )
    assets = job.assets({})
    assert(assets[:User][user1.id], 'check assets')
    assert(assets[:User][user2.id], 'check assets')
    assert_not(assets[:User][user3.id], 'check assets')
    assert(assets[:TicketState][ticket_state1.id], 'check assets')
    assert(assets[:TicketState][ticket_state2.id], 'check assets')
    assert(assets[:TicketPriority][ticket_priority2.id], 'check assets')

  end

end
