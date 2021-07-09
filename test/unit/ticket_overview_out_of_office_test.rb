# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class TicketOverviewOutOfOfficeTest < ActiveSupport::TestCase

  setup do
    group = Group.create_or_update(
      name:          'OverviewReplacementTest',
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Agent')
    @agent1 = User.create_or_update(
      login:         'ticket-overview-agent1@example.com',
      firstname:     'Overview',
      lastname:      'Agent1',
      email:         'ticket-overview-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        [group],
      out_of_office: false,
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    @agent2 = User.create_or_update(
      login:         'ticket-overview-agent2@example.com',
      firstname:     'Overview',
      lastname:      'Agent2',
      email:         'ticket-overview-agent2@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        [group],
      out_of_office: false,
      updated_at:    '2015-02-05 16:38:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    organization1 = Organization.create_or_update(
      name:          'Overview Org',
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    @customer1 = User.create_or_update(
      login:           'ticket-overview-customer1@example.com',
      firstname:       'Overview',
      lastname:        'Customer1',
      email:           'ticket-overview-customer1@example.com',
      password:        'customerpw',
      active:          true,
      organization_id: organization1.id,
      roles:           roles,
      out_of_office:   false,
      updated_at:      '2015-02-05 16:37:00',
      updated_by_id:   1,
      created_by_id:   1,
    )

    Overview.destroy_all
    UserInfo.current_user_id = 1
    overview_role = Role.find_by(name: 'Agent')
    @overview1 = Overview.create_or_update(
      name:          'My replacement Tickets',
      link:          'my_replacement',
      prio:          1000,
      role_ids:      [overview_role.id],
      out_of_office: true,
      condition:     {
        'ticket.state_id'                     => {
          operator: 'is',
          value:    Ticket::State.by_category(:open).pluck(:id),
        },
        'ticket.out_of_office_replacement_id' => {
          operator:      'is',
          pre_condition: 'current_user.id',
        },
      },
      order:         {
        by:        'created_at',
        direction: 'ASC',
      },
      view:          {
        d:                 %w[title customer group created_at],
        s:                 %w[title customer group created_at],
        m:                 %w[number title customer group created_at],
        view_mode_default: 's',
      },
    )
    @overview2 = Overview.create_if_not_exists(
      name:      'My assigned Tickets',
      link:      'my_assigned',
      prio:      900,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value:    Ticket::State.by_category(:open).pluck(:id),
        },
        'ticket.owner_id' => {
          operator:      'is',
          pre_condition: 'current_user.id',
        },
      },
      order:     {
        by:        'created_at',
        direction: 'ASC',
      },
      view:      {
        d:                 %w[title customer group created_at],
        s:                 %w[title customer group created_at],
        m:                 %w[number title customer group created_at],
        view_mode_default: 's',
      },
    )

    overview_role = Role.find_by(name: 'Customer')
    @overview3 = Overview.create_or_update(
      name:          'My Tickets',
      link:          'my_tickets',
      prio:          1100,
      role_ids:      [overview_role.id],
      out_of_office: false,
      condition:     {
        'ticket.state_id'                     => {
          operator: 'is',
          value:    [1, 2, 3, 4, 6, 7],
        },
        'ticket.out_of_office_replacement_id' => {
          operator:      'is',
          pre_condition: 'current_user.organization_id',
        },
      },
      order:         {
        by:        'created_at',
        direction: 'DESC',
      },
      view:          {
        d:                 %w[title customer state created_at],
        s:                 %w[number title state created_at],
        m:                 %w[number title state created_at],
        view_mode_default: 's',
      },
    )

  end

  test 'overview index' do
    result = Ticket::Overviews.all(
      current_user: @agent1,
    )
    assert_equal(1, result.count)
    assert_equal('My assigned Tickets', result[0].name)

    result = Ticket::Overviews.all(
      current_user: @agent2,
    )
    assert_equal(1, result.count)
    assert_equal('My assigned Tickets', result[0].name)

    result = Ticket::Overviews.all(
      current_user: @customer1,
    )
    assert_equal(1, result.count)
    assert_equal('My Tickets', result[0].name)
    @agent1.out_of_office = true
    @agent1.out_of_office_start_at = Time.zone.now - 2.days
    @agent1.out_of_office_end_at = Time.zone.now + 2.days
    @agent1.out_of_office_replacement_id = @agent2.id
    @agent1.save!

    result = Ticket::Overviews.all(
      current_user: @agent1,
    )
    assert_equal(1, result.count)
    assert_equal('My assigned Tickets', result[0].name)

    result = Ticket::Overviews.all(
      current_user: @agent2,
    )
    assert_equal(2, result.count)
    assert_equal('My assigned Tickets', result[0].name)
    assert_equal('My replacement Tickets', result[1].name)

    result = Ticket::Overviews.all(
      current_user: @customer1,
    )
    assert_equal(1, result.count)
    assert_equal('My Tickets', result[0].name)
  end

  test 'overview shown' do
    result = Ticket::Overviews.index(@agent1)
    assert(result[0])
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)

    result = Ticket::Overviews.index(@agent2)
    assert(result[0])
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)

    result = Ticket::Overviews.index(@customer1)
    assert(result[0])
    assert_equal(result[0][:overview][:name], 'My Tickets')
    assert_equal(result[0][:overview][:view], 'my_tickets')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)

    @agent1.out_of_office = true
    @agent1.out_of_office_start_at = Time.zone.now - 2.days
    @agent1.out_of_office_end_at = Time.zone.now + 2.days
    @agent1.out_of_office_replacement_id = @agent2.id
    @agent1.save!

    assert_equal(@agent2.out_of_office_agent_of.count, 1)
    assert(@agent2.out_of_office_agent_of[0])
    assert_equal(@agent2.out_of_office_agent_of[0].id, @agent1.id)

    result = Ticket::Overviews.index(@agent1)
    assert(result[0])
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)

    result = Ticket::Overviews.index(@agent2)
    assert(result[0])
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert(result[1])
    assert_equal(result[1][:overview][:name], 'My replacement Tickets')
    assert_equal(result[1][:overview][:view], 'my_replacement')
    assert_equal(result[1][:count], 0)
    assert_equal(result[1][:tickets].class, Array)
    assert(result[1][:tickets].blank?)

    result = Ticket::Overviews.index(@customer1)
    assert(result[0])
    assert_equal(result[0][:overview][:name], 'My Tickets')
    assert_equal(result[0][:overview][:view], 'my_tickets')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)

    ticket1 = Ticket.create!(
      title:         'overview test 1',
      group:         Group.lookup(name: 'OverviewReplacementTest'),
      customer_id:   2,
      owner_id:      @agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message... 123',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    result = Ticket::Overviews.index(@agent1)
    assert(result[0])
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 1)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets])
    assert_equal(result[0][:tickets][0][:id], ticket1.id)

    result = Ticket::Overviews.index(@agent2)
    assert(result[0])
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert(result[1])
    assert_equal(result[1][:overview][:name], 'My replacement Tickets')
    assert_equal(result[1][:overview][:view], 'my_replacement')
    assert_equal(result[1][:count], 1)
    assert_equal(result[1][:tickets].class, Array)
    assert(result[1][:tickets])
    assert_equal(result[1][:tickets][0][:id], ticket1.id)

    result = Ticket::Overviews.index(@customer1)
    assert(result[0])
    assert_equal(result[0][:overview][:name], 'My Tickets')
    assert_equal(result[0][:overview][:view], 'my_tickets')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)

  end

end
