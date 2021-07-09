# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class TicketSelectorTest < ActiveSupport::TestCase

  setup do
    @group = Group.create_or_update(
      name:          'SelectorTest',
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Agent')
    @agent1 = User.create_or_update(
      login:         'ticket-selector-agent1@example.com',
      firstname:     'Notification',
      lastname:      'Agent1',
      email:         'ticket-selector-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        [@group],
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    @agent2 = User.create_or_update(
      login:         'ticket-selector-agent2@example.com',
      firstname:     'Notification',
      lastname:      'Agent2',
      email:         'ticket-selector-agent2@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      updated_at:    '2015-02-05 16:38:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    @organization1 = Organization.create_if_not_exists(
      name:          'Selector Org',
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    @customer1 = User.create_or_update(
      login:           'ticket-selector-customer1@example.com',
      firstname:       'Notification',
      lastname:        'Customer1',
      email:           'ticket-selector-customer1@example.com',
      password:        'customerpw',
      active:          true,
      organization_id: @organization1.id,
      roles:           roles,
      updated_at:      '2015-02-05 16:37:00',
      updated_by_id:   1,
      created_by_id:   1,
    )
    @customer2 = User.create_or_update(
      login:           'ticket-selector-customer2@example.com',
      firstname:       'Notification',
      lastname:        'Customer2',
      email:           'ticket-selector-customer2@example.com',
      password:        'customerpw',
      active:          true,
      organization_id: nil,
      roles:           roles,
      updated_at:      '2015-02-05 16:37:00',
      updated_by_id:   1,
      created_by_id:   1,
    )

    Ticket.where(group_id: @group.id).destroy_all
  end

  test 'ticket create' do

    Ticket.destroy_all

    ticket1 = Ticket.create!(
      title:         'some title1',
      group:         @group,
      customer_id:   @customer1.id,
      owner_id:      @agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2015-02-05 16:37:00',
      #updated_at: '2015-02-05 17:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')
    assert_equal(ticket1.customer.id, @customer1.id)
    assert_equal(ticket1.organization.id, @organization1.id)
    travel 1.second

    ticket2 = Ticket.create!(
      title:         'some title2',
      group:         @group,
      customer_id:   @customer2.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2015-02-05 16:37:00',
      #updated_at: '2015-02-05 17:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket2, 'ticket created')
    assert_equal(ticket2.customer.id, @customer2.id)
    assert_nil(ticket2.organization_id)
    travel 1.second

    ticket3 = Ticket.create!(
      title:         'some title3',
      group:         @group,
      customer_id:   @customer2.id,
      state:         Ticket::State.lookup(name: 'open'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2015-02-05 16:37:00',
      #updated_at: '2015-02-05 17:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket3.update_columns(escalation_at: '2015-02-06 10:00:00')
    assert(ticket3, 'ticket created')
    assert_equal(ticket3.customer.id, @customer2.id)
    assert_nil(ticket3.organization_id)
    travel 1.second

    # search not matching
    condition = {
      'ticket.state_id' => {
        operator: 'is',
        value:    [99],
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 0)

    # search matching with empty value / missing key
    condition = {
      'ticket.group_id' => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.state_id' => {
        operator: 'is',
      },
    }

    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_nil(ticket_count)

    # search matching with empty value []
    condition = {
      'ticket.group_id' => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.state_id' => {
        operator: 'is',
        value:    [],
      },
    }

    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_nil(ticket_count)

    # search matching with empty value ''
    condition = {
      'ticket.group_id' => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.state_id' => {
        operator: 'is',
      },
    }

    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_nil(ticket_count)

    # search matching
    condition = {
      'ticket.group_id' => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.state_id' => {
        operator: 'is',
        value:    [Ticket::State.lookup(name: 'new').id],
      },
    }

    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_equal(ticket_count, 2)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 2)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 1)

    condition = {
      'ticket.group_id' => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.state_id' => {
        operator: 'is not',
        value:    [Ticket::State.lookup(name: 'open').id],
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_equal(ticket_count, 2)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 2)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 1)

    condition = {
      'ticket.escalation_at' => {
        operator: 'is not',
        value:    nil,
      }
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 1)

    # search - created_at
    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.created_at' => {
        operator: 'after (absolute)', # before (absolute)
        value:    '2015-02-05T16:00:00.000Z',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 3)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 2)

    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.created_at' => {
        operator: 'after (absolute)', # before (absolute)
        value:    '2015-02-05T18:00:00.000Z',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.created_at' => {
        operator: 'before (absolute)',
        value:    '2015-02-05T18:00:00.000Z',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 3)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 2)

    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.created_at' => {
        operator: 'before (absolute)',
        value:    '2015-02-05T16:00:00.000Z',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.created_at' => {
        operator: 'before (relative)',
        range:    'day', # minute|hour|day|month|
        value:    '10',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 3)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 2)

    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.created_at' => {
        operator: 'till (relative)',
        range:    'year', # minute|hour|day|month|
        value:    '10',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 3)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 2)

    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.created_at' => {
        operator: 'within last (relative)',
        range:    'year', # minute|hour|day|month|
        value:    '10',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 3)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 2)

    # search - updated_at
    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.updated_at' => {
        operator: 'before (absolute)',
        value:    (Time.zone.now + 1.day).iso8601,
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 3)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 2)

    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.updated_at' => {
        operator: 'before (absolute)',
        value:    (Time.zone.now - 1.day).iso8601,
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.updated_at' => {
        operator: 'after (absolute)',
        value:    (Time.zone.now + 1.day).iso8601,
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.updated_at' => {
        operator: 'after (absolute)',
        value:    (Time.zone.now - 1.day).iso8601,
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 3)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 2)

    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.updated_at' => {
        operator: 'before (relative)',
        range:    'day', # minute|hour|day|month|
        value:    '10',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.updated_at' => {
        operator: 'till (relative)',
        range:    'year', # minute|hour|day|month|
        value:    '10',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 3)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 2)

    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.updated_at' => {
        operator: 'within last (relative)',
        range:    'year', # minute|hour|day|month|
        value:    '10',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 3)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 2)

    # invalid conditions
    assert_raise RuntimeError do
      ticket_count, tickets = Ticket.selectors(nil, limit: 10)
    end

    # search with customers
    condition = {
      'ticket.group_id' => {
        operator: 'is',
        value:    @group.id,
      },
      'customer.email'  => {
        operator: 'contains',
        value:    'ticket-selector-customer1',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    condition = {
      'ticket.group_id' => {
        operator: 'is',
        value:    @group.id,
      },
      'customer.email'  => {
        operator: 'contains not',
        value:    'ticket-selector-customer1-not_existing',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 3)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 2)

    # search with organizations
    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'organization.name' => {
        operator: 'contains',
        value:    'selector',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    # search with organizations
    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'organization.name' => {
        operator: 'contains',
        value:    'selector',
      },
      'customer.email'    => {
        operator: 'contains',
        value:    'ticket-selector-customer1',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    condition = {
      'ticket.group_id'   => {
        operator: 'is',
        value:    @group.id,
      },
      'organization.name' => {
        operator: 'contains',
        value:    'selector',
      },
      'customer.email'    => {
        operator: 'contains not',
        value:    'ticket-selector-customer1',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    # with owner/customer/org
    condition = {
      'ticket.group_id' => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.owner_id' => {
        operator:      'is',
        pre_condition: 'specific',
        value:         @agent1.id,
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    condition = {
      'ticket.group_id' => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.owner_id' => {
        operator:      'is',
        pre_condition: 'specific',
        #value: @agent1.id, # value is not set, no result should be shown
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_nil(ticket_count)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_nil(ticket_count)

    condition = {
      'ticket.group_id' => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.owner_id' => {
        operator:      'is',
        pre_condition: 'not_set',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 2)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 2)

    condition = {
      'ticket.group_id' => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.owner_id' => {
        operator:      'is not',
        pre_condition: 'not_set',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    UserInfo.current_user_id = @agent1.id
    condition = {
      'ticket.group_id' => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.owner_id' => {
        operator:      'is',
        pre_condition: 'current_user.id',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    UserInfo.current_user_id = @agent2.id
    condition = {
      'ticket.group_id' => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.owner_id' => {
        operator:      'is',
        pre_condition: 'current_user.id',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    UserInfo.current_user_id = @customer1.id
    condition = {
      'ticket.group_id'    => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.customer_id' => {
        operator:      'is',
        pre_condition: 'current_user.id',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 2)

    UserInfo.current_user_id = @customer2.id
    condition = {
      'ticket.group_id'    => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.customer_id' => {
        operator:      'is',
        pre_condition: 'current_user.id',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 2)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_equal(ticket_count, 2)

    UserInfo.current_user_id = @customer1.id
    condition = {
      'ticket.group_id'        => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.organization_id' => {
        operator:      'is',
        pre_condition: 'current_user.organization_id',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    UserInfo.current_user_id = @customer2.id
    condition = {
      'ticket.group_id'        => {
        operator: 'is',
        value:    @group.id,
      },
      'ticket.organization_id' => {
        operator:      'is',
        pre_condition: 'current_user.organization_id',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer1)
    assert_equal(ticket_count, 1)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10, current_user: @customer2)
    assert_equal(ticket_count, 0)

    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_equal(ticket_count, 0)
    travel_back
  end

  test 'ticket tags filter' do
    ticket_tags_1 = Ticket.create!(
      title:         'some title1',
      group:         @group,
      customer_id:   @customer1.id,
      owner_id:      @agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket_tags_2 = Ticket.create!(
      title:         'some title1',
      group:         @group,
      customer_id:   @customer1.id,
      owner_id:      @agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket.create!(
      title:         'some title1',
      group:         @group,
      customer_id:   @customer1.id,
      owner_id:      @agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )

    Tag.tag_add(
      object:        'Ticket',
      o_id:          ticket_tags_1.id,
      item:          'contains_all_1',
      created_by_id: 1,
    )
    Tag.tag_add(
      object:        'Ticket',
      o_id:          ticket_tags_1.id,
      item:          'contains_all_2',
      created_by_id: 1,
    )
    Tag.tag_add(
      object:        'Ticket',
      o_id:          ticket_tags_1.id,
      item:          'contains_all_3',
      created_by_id: 1,
    )
    Tag.tag_add(
      object:        'Ticket',
      o_id:          ticket_tags_2.id,
      item:          'contains_all_3',
      created_by_id: 1,
    )

    # search all with contains all
    condition = {
      'ticket.tags' => {
        operator: 'contains all',
        value:    'contains_all_1, contains_all_2, contains_all_3',
      },
    }
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(1, ticket_count)

    condition = {
      'ticket.tags' => {
        operator: 'contains all',
        value:    'contains_all_1, contains_all_2, contains_all_3, xxx',
      },
    }
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(0, ticket_count)

    # search all with contains one
    condition = {
      'ticket.tags' => {
        operator: 'contains one',
        value:    'contains_all_1, contains_all_2, contains_all_3',
      },
    }
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(2, ticket_count)

    condition = {
      'ticket.tags' => {
        operator: 'contains one',
        value:    'contains_all_1, contains_all_2'
      },
    }
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(1, ticket_count)

    # search all with contains one not
    condition = {
      'ticket.tags' => {
        operator: 'contains one',
        value:    'contains_all_1, contains_all_3'
      },
    }
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(2, ticket_count)

    condition = {
      'ticket.tags' => {
        operator: 'contains one',
        value:    'contains_all_1, contains_all_2, contains_all_3'
      },
    }
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(2, ticket_count)
  end

  test 'ticket title with certain content' do
    Ticket.create!(
      title:         'some_title1',
      group:         @group,
      customer_id:   @customer1.id,
      owner_id:      @agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket.create!(
      title:         'some::title2',
      group:         @group,
      customer_id:   @customer1.id,
      owner_id:      @agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket.create!(
      title:         'some-title3',
      group:         @group,
      customer_id:   @customer1.id,
      owner_id:      @agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )

    # search all with contains
    condition = {
      'ticket.title' => {
        operator: 'contains',
        value:    'some_title1',
      },
    }
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(1, ticket_count)

    condition = {
      'ticket.title' => {
        operator: 'contains',
        value:    'some::title2',
      },
    }
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(1, ticket_count)

    condition = {
      'ticket.title' => {
        operator: 'contains',
        value:    'some-title3',
      },
    }
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(1, ticket_count)

    # search all with is
    condition = {
      'ticket.title' => {
        operator: 'is',
        value:    'some_title1',
      },
    }
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(1, ticket_count)

    condition = {
      'ticket.title' => {
        operator: 'is',
        value:    'some::title2',
      },
    }
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(1, ticket_count)

    condition = {
      'ticket.title' => {
        operator: 'is',
        value:    'some-title3',
      },
    }
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(1, ticket_count)

  end

  test 'access: "ignore"' do
    Ticket.destroy_all

    Ticket.create!(
      title:         'some title1',
      group:         @group,
      customer_id:   @customer1.id,
      owner_id:      @agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )

    Ticket.create!(
      title:         'some title2',
      group:         @group,
      customer_id:   @customer1.id,
      owner_id:      @agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2015-02-05 16:37:00',
      updated_by_id: @agent2.id,
      created_by_id: 1,
    )

    condition = {
      'ticket.title' => {
        operator: 'contains',
        value:    'some',
      },
    }

    # visible by owner
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent1)
    assert_equal(2, ticket_count)

    # not visible by another agent
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2)
    assert_equal(0, ticket_count)

    # visible by another user when access: "ignore". For example, when tickets are performed after action of another user
    ticket_count, _tickets = Ticket.selectors(condition, limit: 10, current_user: @agent2, access: 'ignore')
    assert_equal(2, ticket_count)

    condition2 = {
      'ticket.updated_by_id' => {
        operator:         'is',
        pre_condition:    'current_user.id',
        value:            '',
        value_completion: ''
      }
    }

    # not visible by another agent even if matches current user precondition
    ticket_count, _tickets = Ticket.selectors(condition2, limit: 10, current_user: @agent2)
    assert_equal(0, ticket_count)

    # visible by another user when access: "ignore" if matches current user precondition
    ticket_count, _tickets = Ticket.selectors(condition2, limit: 10, current_user: @agent2, access: 'ignore')
    assert_equal(1, ticket_count)
  end
end
