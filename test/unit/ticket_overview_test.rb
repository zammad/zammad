# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class TicketOverviewTest < ActiveSupport::TestCase

  setup do
    group = Group.create_or_update(
      name:          'OverviewTest',
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
      #groups: groups,
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
      updated_at:      '2015-02-05 16:37:00',
      updated_by_id:   1,
      created_by_id:   1,
    )
    @customer2 = User.create_or_update(
      login:           'ticket-overview-customer2@example.com',
      firstname:       'Overview',
      lastname:        'Customer2',
      email:           'ticket-overview-customer2@example.com',
      password:        'customerpw',
      active:          true,
      organization_id: organization1.id,
      roles:           roles,
      updated_at:      '2015-02-05 16:37:00',
      updated_by_id:   1,
      created_by_id:   1,
    )
    @customer3 = User.create_or_update(
      login:           'ticket-overview-customer3@example.com',
      firstname:       'Overview',
      lastname:        'Customer3',
      email:           'ticket-overview-customer3@example.com',
      password:        'customerpw',
      active:          true,
      organization_id: nil,
      roles:           roles,
      updated_at:      '2015-02-05 16:37:00',
      updated_by_id:   1,
      created_by_id:   1,
    )
    Overview.destroy_all
    UserInfo.current_user_id = 1
    overview_role = Role.find_by(name: 'Agent')
    @overview1 = Overview.create_or_update(
      name:      'My assigned Tickets',
      link:      'my_assigned',
      prio:      1000,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value:    [1, 2, 3, 7],
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

    @overview2 = Overview.create_or_update(
      name:      'Unassigned & Open',
      link:      'all_unassigned',
      prio:      1010,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value:    [1, 2, 3],
        },
        'ticket.owner_id' => {
          operator: 'is',
          value:    1,
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
    @overview3 = Overview.create_or_update(
      name:      'My Tickets 2',
      link:      'my_tickets_2',
      prio:      1020,
      role_ids:  [overview_role.id],
      user_ids:  [@agent2.id],
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value:    [1, 2, 3, 7],
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
    @overview4 = Overview.create_or_update(
      name:      'My Tickets only with Note',
      link:      'my_tickets_onyl_with_note',
      prio:      1030,
      role_ids:  [overview_role.id],
      user_ids:  [@agent1.id],
      condition: {
        'article.type_id' => {
          operator: 'is',
          value:    Ticket::Article::Type.find_by(name: 'note').id,
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
    @overview5 = Overview.create_or_update(
      name:      'My Tickets',
      link:      'my_tickets',
      prio:      1100,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.state_id'    => {
          operator: 'is',
          value:    [1, 2, 3, 4, 6, 7],
        },
        'ticket.customer_id' => {
          operator:      'is',
          pre_condition: 'current_user.id',
        },
      },
      order:     {
        by:        'created_at',
        direction: 'DESC',
      },
      view:      {
        d:                 %w[title customer state created_at],
        s:                 %w[number title state created_at],
        m:                 %w[number title state created_at],
        view_mode_default: 's',
      },
    )
    @overview6 = Overview.create_or_update(
      name:                'My Organization Tickets',
      link:                'my_organization_tickets',
      prio:                1200,
      role_ids:            [overview_role.id],
      organization_shared: true,
      condition:           {
        'ticket.state_id'        => {
          operator: 'is',
          value:    [1, 2, 3, 4, 6, 7],
        },
        'ticket.organization_id' => {
          operator:      'is',
          pre_condition: 'current_user.organization_id',
        },
      },
      order:               {
        by:        'created_at',
        direction: 'DESC',
      },
      view:                {
        d:                 %w[title customer state created_at],
        s:                 %w[number title customer state created_at],
        m:                 %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )
    @overview7 = Overview.create_or_update(
      name:                'My Organization Tickets (open)',
      link:                'my_organization_tickets_open',
      prio:                1200,
      role_ids:            [overview_role.id],
      user_ids:            [@customer2.id],
      organization_shared: true,
      condition:           {
        'ticket.state_id'        => {
          operator: 'is',
          value:    [1, 2, 3],
        },
        'ticket.organization_id' => {
          operator:      'is',
          pre_condition: 'current_user.organization_id',
        },
      },
      order:               {
        by:        'created_at',
        direction: 'DESC',
      },
      view:                {
        d:                 %w[title customer state created_at],
        s:                 %w[number title customer state created_at],
        m:                 %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )

    overview_role = Role.find_by(name: 'Admin')
    @overview8 = Overview.create_or_update(
      name:      'Not Shown Admin',
      link:      'not_shown_admin',
      prio:      9900,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value:    [1, 2, 3],
        },
      },
      order:     {
        by:        'created_at',
        direction: 'DESC',
      },
      view:      {
        d:                 %w[title customer state created_at],
        s:                 %w[number title customer state created_at],
        m:                 %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )
  end

  test 'overview index' do

    result = Ticket::Overviews.all(
      current_user: @agent1,
    )

    assert_equal(3, result.count)
    assert_equal('My assigned Tickets', result[0].name)
    assert_equal('Unassigned & Open', result[1].name)
    assert_equal('My Tickets only with Note', result[2].name)

    result = Ticket::Overviews.all(
      current_user: @agent2,
    )
    assert_equal(3, result.count)
    assert_equal('My assigned Tickets', result[0].name)
    assert_equal('Unassigned & Open', result[1].name)
    assert_equal('My Tickets 2', result[2].name)

    result = Ticket::Overviews.all(
      current_user: @customer1,
    )
    assert_equal(2, result.count)
    assert_equal('My Tickets', result[0].name)
    assert_equal('My Organization Tickets', result[1].name)

    result = Ticket::Overviews.all(
      current_user: @customer2,
    )
    assert_equal(3, result.count)
    assert_equal('My Tickets', result[0].name)
    assert_equal('My Organization Tickets', result[1].name)
    assert_equal('My Organization Tickets (open)', result[2].name)

    result = Ticket::Overviews.all(
      current_user: @customer3,
    )
    assert_equal(1, result.count)
    assert_equal('My Tickets', result[0].name)

  end

  test 'missing role' do
    Ticket.destroy_all

    assert_raises(Exception) do
      Overview.create!(
        name:                'new overview',
        link:                'new_overview',
        prio:                1200,
        user_ids:            [@customer2.id],
        organization_shared: true,
        condition:           {
          'ticket.state_id'        => {
            operator: 'is',
            value:    [1, 2, 3],
          },
          'ticket.organization_id' => {
            operator:      'is',
            pre_condition: 'current_user.organization_id',
          },
        },
        order:               {
          by:        'created_at',
          direction: 'DESC',
        },
        view:                {
          d:                 %w[title customer state created_at],
          s:                 %w[number title customer state created_at],
          m:                 %w[number title customer state created_at],
          view_mode_default: 's',
        },
      )
    end

  end

  test 'overview content' do

    Ticket.destroy_all

    result = Ticket::Overviews.index(@agent1)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert(result[1][:tickets].blank?)
    assert_equal(result[1][:count], 0)
    assert_equal(result[2][:overview][:name], 'My Tickets only with Note')
    assert_equal(result[2][:overview][:view], 'my_tickets_onyl_with_note')
    assert_equal(result[2][:tickets].class, Array)
    assert(result[2][:tickets].blank?)
    assert_equal(result[2][:count], 0)

    result = Ticket::Overviews.index(@agent2)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert(result[1][:tickets].blank?)
    assert_equal(result[1][:count], 0)
    assert_equal(result[2][:overview][:name], 'My Tickets 2')
    assert_equal(result[2][:overview][:view], 'my_tickets_2')
    assert_equal(result[2][:tickets].class, Array)
    assert(result[2][:tickets].blank?)

    ticket1 = Ticket.create!(
      title:         'overview test 1',
      group:         Group.lookup(name: 'OverviewTest'),
      customer_id:   2,
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
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert_not(result[1][:tickets].blank?)
    assert_equal(result[1][:tickets][0][:id], ticket1.id)
    assert_equal(result[1][:count], 1)
    assert_equal(result[2][:overview][:name], 'My Tickets only with Note')
    assert_equal(result[2][:overview][:view], 'my_tickets_onyl_with_note')
    assert_equal(result[2][:tickets].class, Array)
    assert(result[2][:tickets].blank?)
    assert_equal(result[2][:count], 0)

    result = Ticket::Overviews.index(@agent2)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert(result[1][:tickets].blank?)
    assert_equal(result[1][:count], 0)
    assert_equal(result[2][:overview][:name], 'My Tickets 2')
    assert_equal(result[2][:overview][:view], 'my_tickets_2')
    assert_equal(result[2][:tickets].class, Array)
    assert(result[2][:tickets].blank?)

    travel 1.second # because of mysql millitime issues
    ticket2 = Ticket.create!(
      title:         'overview test 2',
      group:         Group.lookup(name: 'OverviewTest'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '3 high'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id:     ticket2.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message... 123',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      type:          Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    result = Ticket::Overviews.index(@agent1)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert_not(result[1][:tickets].blank?)
    assert_equal(result[1][:tickets][0][:id], ticket1.id)
    assert_equal(result[1][:tickets][1][:id], ticket2.id)
    assert_equal(result[1][:count], 2)
    assert_equal(result[2][:overview][:name], 'My Tickets only with Note')
    assert_equal(result[2][:overview][:view], 'my_tickets_onyl_with_note')
    assert_equal(result[2][:tickets].class, Array)
    assert(result[2][:tickets].blank?)
    assert_equal(result[2][:count], 0)

    result = Ticket::Overviews.index(@agent2)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert(result[1][:tickets].blank?)
    assert_equal(result[1][:count], 0)
    assert_equal(result[2][:overview][:name], 'My Tickets 2')
    assert_equal(result[2][:overview][:view], 'my_tickets_2')
    assert_equal(result[2][:tickets].class, Array)
    assert(result[2][:tickets].blank?)

    ticket2.owner_id = @agent1.id
    ticket2.save!

    result = Ticket::Overviews.index(@agent1)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[0][:tickets][0][:id], ticket2.id)
    assert_equal(result[0][:count], 1)
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert_not(result[1][:tickets].blank?)
    assert_equal(result[1][:tickets][0][:id], ticket1.id)
    assert_equal(result[1][:count], 1)
    assert_equal(result[2][:overview][:name], 'My Tickets only with Note')
    assert_equal(result[2][:overview][:view], 'my_tickets_onyl_with_note')
    assert_equal(result[2][:tickets].class, Array)
    assert_equal(result[2][:tickets][0][:id], ticket2.id)
    assert_equal(result[2][:count], 1)

    result = Ticket::Overviews.index(@agent2)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert(result[1][:tickets].blank?)
    assert_equal(result[1][:count], 0)
    assert_equal(result[2][:overview][:name], 'My Tickets 2')
    assert_equal(result[2][:overview][:view], 'my_tickets_2')
    assert_equal(result[2][:tickets].class, Array)
    assert(result[2][:tickets].blank?)

    travel 1.second # because of mysql millitime issues
    ticket3 = Ticket.create!(
      title:         'overview test 3',
      group:         Group.lookup(name: 'OverviewTest'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '1 low'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id:     ticket3.id,
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
    travel_back

    result = Ticket::Overviews.index(@agent1)
    assert_equal(result[0][:overview][:id], @overview1.id)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[0][:tickets][0][:id], ticket2.id)
    assert_equal(result[0][:count], 1)
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[1][:overview][:id], @overview2.id)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert_not(result[1][:tickets].blank?)
    assert_equal(result[1][:tickets][0][:id], ticket1.id)
    assert_equal(result[1][:tickets][1][:id], ticket3.id)
    assert_equal(result[1][:count], 2)
    assert_equal(result[2][:overview][:id], @overview4.id)
    assert_equal(result[2][:overview][:name], 'My Tickets only with Note')
    assert_equal(result[2][:overview][:view], 'my_tickets_onyl_with_note')
    assert_equal(result[2][:tickets].class, Array)
    assert_equal(result[2][:tickets][0][:id], ticket2.id)
    assert_equal(result[2][:count], 1)

    result = Ticket::Overviews.index(@agent2)
    assert_equal(result[0][:overview][:id], @overview1.id)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert_equal(result[1][:overview][:id], @overview2.id)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert(result[1][:tickets].blank?)
    assert_equal(result[1][:count], 0)
    assert_equal(result[2][:overview][:id], @overview3.id)
    assert_equal(result[2][:overview][:name], 'My Tickets 2')
    assert_equal(result[2][:overview][:view], 'my_tickets_2')
    assert_equal(result[2][:tickets].class, Array)
    assert(result[2][:tickets].blank?)

    @overview2.order = {
      by:        'created_at',
      direction: 'DESC',
    }
    @overview2.save!

    result = Ticket::Overviews.index(@agent1)
    assert_equal(result[0][:overview][:id], @overview1.id)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[0][:tickets][0][:id], ticket2.id)
    assert_equal(result[0][:count], 1)
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[1][:overview][:id], @overview2.id)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert_not(result[1][:tickets].blank?)
    assert_equal(result[1][:tickets][0][:id], ticket3.id)
    assert_equal(result[1][:tickets][1][:id], ticket1.id)
    assert_equal(result[1][:count], 2)
    assert_equal(result[2][:overview][:id], @overview4.id)
    assert_equal(result[2][:overview][:name], 'My Tickets only with Note')
    assert_equal(result[2][:overview][:view], 'my_tickets_onyl_with_note')
    assert_equal(result[2][:tickets].class, Array)
    assert_equal(result[2][:tickets][0][:id], ticket2.id)
    assert_equal(result[2][:count], 1)

    result = Ticket::Overviews.index(@agent2)
    assert_equal(result[0][:overview][:id], @overview1.id)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert_equal(result[1][:overview][:id], @overview2.id)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert(result[1][:tickets].blank?)
    assert_equal(result[1][:count], 0)
    assert_equal(result[2][:overview][:id], @overview3.id)
    assert_equal(result[2][:overview][:name], 'My Tickets 2')
    assert_equal(result[2][:overview][:view], 'my_tickets_2')
    assert_equal(result[2][:tickets].class, Array)
    assert(result[2][:tickets].blank?)

    @overview2.order = {
      by:        'priority_id',
      direction: 'DESC',
    }
    @overview2.save!

    result = Ticket::Overviews.index(@agent1)
    assert_equal(result[0][:overview][:id], @overview1.id)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[0][:tickets][0][:id], ticket2.id)
    assert_equal(result[0][:count], 1)
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[1][:overview][:id], @overview2.id)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert_not(result[1][:tickets].blank?)
    assert_equal(result[1][:tickets][0][:id], ticket1.id)
    assert_equal(result[1][:tickets][1][:id], ticket3.id)
    assert_equal(result[1][:count], 2)
    assert_equal(result[2][:overview][:id], @overview4.id)
    assert_equal(result[2][:overview][:name], 'My Tickets only with Note')
    assert_equal(result[2][:overview][:view], 'my_tickets_onyl_with_note')
    assert_equal(result[2][:tickets].class, Array)
    assert_equal(result[2][:tickets][0][:id], ticket2.id)
    assert_equal(result[2][:count], 1)

    result = Ticket::Overviews.index(@agent2)
    assert_equal(result[0][:overview][:id], @overview1.id)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert_equal(result[1][:overview][:id], @overview2.id)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert(result[1][:tickets].blank?)
    assert_equal(result[1][:count], 0)
    assert_equal(result[2][:overview][:id], @overview3.id)
    assert_equal(result[2][:overview][:name], 'My Tickets 2')
    assert_equal(result[2][:overview][:view], 'my_tickets_2')
    assert_equal(result[2][:tickets].class, Array)
    assert(result[2][:tickets].blank?)

    @overview2.order = {
      by:        'priority_id',
      direction: 'ASC',
    }
    @overview2.save!

    result = Ticket::Overviews.index(@agent1)
    assert_equal(result[0][:overview][:id], @overview1.id)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[0][:tickets][0][:id], ticket2.id)
    assert_equal(result[0][:count], 1)
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[1][:overview][:id], @overview2.id)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert_not(result[1][:tickets].blank?)
    assert_equal(result[1][:tickets][0][:id], ticket3.id)
    assert_equal(result[1][:tickets][1][:id], ticket1.id)
    assert_equal(result[1][:count], 2)
    assert_equal(result[2][:overview][:id], @overview4.id)
    assert_equal(result[2][:overview][:name], 'My Tickets only with Note')
    assert_equal(result[2][:overview][:view], 'my_tickets_onyl_with_note')
    assert_equal(result[2][:tickets].class, Array)
    assert_equal(result[2][:tickets][0][:id], ticket2.id)
    assert_equal(result[2][:count], 1)

    result = Ticket::Overviews.index(@agent2)
    assert_equal(result[0][:overview][:id], @overview1.id)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert_equal(result[1][:overview][:id], @overview2.id)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert(result[1][:tickets].blank?)
    assert_equal(result[1][:count], 0)
    assert_equal(result[2][:overview][:id], @overview3.id)
    assert_equal(result[2][:overview][:name], 'My Tickets 2')
    assert_equal(result[2][:overview][:view], 'my_tickets_2')
    assert_equal(result[2][:tickets].class, Array)
    assert(result[2][:tickets].blank?)

    @overview2.order = {
      by:        'priority',
      direction: 'DESC',
    }
    @overview2.save!

    result = Ticket::Overviews.index(@agent1)
    assert_equal(result[0][:overview][:id], @overview1.id)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[0][:tickets][0][:id], ticket2.id)
    assert_equal(result[0][:count], 1)
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[1][:overview][:id], @overview2.id)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert_not(result[1][:tickets].blank?)
    assert_equal(result[1][:tickets][0][:id], ticket1.id)
    assert_equal(result[1][:tickets][1][:id], ticket3.id)
    assert_equal(result[1][:count], 2)
    assert_equal(result[2][:overview][:id], @overview4.id)
    assert_equal(result[2][:overview][:name], 'My Tickets only with Note')
    assert_equal(result[2][:overview][:view], 'my_tickets_onyl_with_note')
    assert_equal(result[2][:tickets].class, Array)
    assert_equal(result[2][:tickets][0][:id], ticket2.id)
    assert_equal(result[2][:count], 1)

    result = Ticket::Overviews.index(@agent2)
    assert_equal(result[0][:overview][:id], @overview1.id)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert_equal(result[1][:overview][:id], @overview2.id)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert(result[1][:tickets].blank?)
    assert_equal(result[1][:count], 0)
    assert_equal(result[2][:overview][:id], @overview3.id)
    assert_equal(result[2][:overview][:name], 'My Tickets 2')
    assert_equal(result[2][:overview][:view], 'my_tickets_2')
    assert_equal(result[2][:tickets].class, Array)
    assert(result[2][:tickets].blank?)

    @overview2.order = {
      by:        'priority',
      direction: 'ASC',
    }
    @overview2.save!

    result = Ticket::Overviews.index(@agent1)
    assert_equal(result[0][:overview][:id], @overview1.id)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[0][:tickets][0][:id], ticket2.id)
    assert_equal(result[0][:count], 1)
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[1][:overview][:id], @overview2.id)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert_not(result[1][:tickets].blank?)
    assert_equal(result[1][:tickets][0][:id], ticket3.id)
    assert_equal(result[1][:tickets][1][:id], ticket1.id)
    assert_equal(result[1][:count], 2)
    assert_equal(result[2][:overview][:id], @overview4.id)
    assert_equal(result[2][:overview][:name], 'My Tickets only with Note')
    assert_equal(result[2][:overview][:view], 'my_tickets_onyl_with_note')
    assert_equal(result[2][:tickets].class, Array)
    assert_equal(result[2][:tickets][0][:id], ticket2.id)
    assert_equal(result[2][:count], 1)

    result = Ticket::Overviews.index(@agent2)
    assert_equal(result[0][:overview][:id], @overview1.id)
    assert_equal(result[0][:overview][:name], 'My assigned Tickets')
    assert_equal(result[0][:overview][:view], 'my_assigned')
    assert_equal(result[0][:count], 0)
    assert_equal(result[0][:tickets].class, Array)
    assert(result[0][:tickets].blank?)
    assert_equal(result[1][:overview][:id], @overview2.id)
    assert_equal(result[1][:overview][:name], 'Unassigned & Open')
    assert_equal(result[1][:overview][:view], 'all_unassigned')
    assert_equal(result[1][:tickets].class, Array)
    assert(result[1][:tickets].blank?)
    assert_equal(result[1][:count], 0)
    assert_equal(result[2][:overview][:id], @overview3.id)
    assert_equal(result[2][:overview][:name], 'My Tickets 2')
    assert_equal(result[2][:overview][:view], 'my_tickets_2')
    assert_equal(result[2][:tickets].class, Array)
    assert(result[2][:tickets].blank?)

  end

  test 'overview any owner / no owner is set' do

    Ticket.destroy_all
    Overview.destroy_all

    UserInfo.current_user_id = 1
    overview_role = Role.find_by(name: 'Agent')
    overview1 = Overview.create_or_update(
      name:      'not owned',
      prio:      1000,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.owner_id' => {
          operator:      'is',
          pre_condition: 'not_set',
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

    overview2 = Overview.create_or_update(
      name:      'not owned by somebody',
      prio:      2000,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.owner_id' => {
          operator:      'is not',
          pre_condition: 'not_set',
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

    ticket1 = Ticket.create!(
      title:       'overview test 1',
      group:       Group.lookup(name: 'OverviewTest'),
      customer_id: 2,
      owner_id:    1,
      state:       Ticket::State.lookup(name: 'new'),
      priority:    Ticket::Priority.lookup(name: '2 normal'),
    )

    travel 2.seconds
    ticket2 = Ticket.create!(
      title:       'overview test 2',
      group:       Group.lookup(name: 'OverviewTest'),
      customer_id: 2,
      owner_id:    nil,
      state:       Ticket::State.lookup(name: 'new'),
      priority:    Ticket::Priority.lookup(name: '2 normal'),
    )

    travel 2.seconds
    ticket3 = Ticket.create!(
      title:       'overview test 3',
      group:       Group.lookup(name: 'OverviewTest'),
      customer_id: 2,
      owner_id:    @agent1.id,
      state:       Ticket::State.lookup(name: 'new'),
      priority:    Ticket::Priority.lookup(name: '2 normal'),
    )

    result = Ticket::Overviews.index(@agent1)
    assert_equal(result[0][:overview][:id], overview1.id)
    assert_equal(result[0][:overview][:name], 'not owned')
    assert_equal(result[0][:overview][:view], 'not_owned')
    assert_equal(result[0][:tickets].class, Array)

    assert_equal(result[0][:tickets][0][:id], ticket1.id)
    assert_equal(result[0][:tickets][1][:id], ticket2.id)
    assert_equal(result[0][:count], 2)

    assert_equal(result[1][:overview][:id], overview2.id)
    assert_equal(result[1][:overview][:name], 'not owned by somebody')
    assert_equal(result[1][:overview][:view], 'not_owned_by_somebody')
    assert_equal(result[1][:tickets].class, Array)
    assert_equal(result[1][:tickets][0][:id], ticket3.id)
    assert_equal(result[1][:count], 1)

  end
end
