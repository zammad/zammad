# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class TicketLastOwnerUpdateTest < ActiveSupport::TestCase

  setup do
    Group.create_or_update(
      name:               'LastOwnerUpdate',
      email_address:      EmailAddress.first,
      assignment_timeout: 60,
      updated_by_id:      1,
      created_by_id:      1,
    )
    roles = Role.where(name: 'Agent')
    @agent1 = User.create_or_update(
      login:         'ticket-assignment_timeout-agent1@example.com',
      firstname:     'Overview',
      lastname:      'Agent1',
      email:         'ticket-assignment_timeout-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        Group.all,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  test 'last_owner_update_at check by state' do

    ticket = Ticket.create!(
      title:         'assignment_timeout test by state 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         @agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_in_delta(ticket.last_owner_update_at.to_i, ticket.updated_at.to_i, 1)

    ticket.state = Ticket::State.lookup(name: 'closed')
    ticket.save!
    assert_nil(ticket.last_owner_update_at)

    ticket = Ticket.create!(
      title:         'assignment_timeout test by state 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         @agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'pending reminder'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_nil(ticket.last_owner_update_at)

    ticket.state = Ticket::State.lookup(name: 'open')
    ticket.save!

    assert_in_delta(ticket.updated_at.to_i, ticket.last_owner_update_at.to_i, 1)

  end

  test 'last_owner_update_at check with agent reply' do

    ticket = Ticket.create!(
      title:         'assignment_timeout test by state 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         @agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'open'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_in_delta(ticket.updated_at.to_i, ticket.last_owner_update_at.to_i, 1)

    travel 1.hour

    Ticket::Article.create(
      ticket_id:     ticket.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message reply by customer email',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 2,
      created_by_id: 2,
    )

    ticket_last_owner_update_at = ticket.last_owner_update_at
    ticket.reload

    assert_in_delta(ticket.last_owner_update_at.to_i, ticket_last_owner_update_at.to_i, 1)

    travel 1.hour

    Ticket::Article.create(
      ticket_id:     ticket.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message reply by agent email',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )

    ticket_last_owner_update_at = Time.zone.now
    ticket.reload

    assert_in_delta(ticket.last_owner_update_at.to_i, ticket_last_owner_update_at.to_i, 1)

  end

  test 'last_owner_update_at check' do

    ticket = Ticket.create!(
      title:         'assignment_timeout test 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_nil(ticket.last_owner_update_at)

    travel 1.hour
    ticket.owner = @agent1
    ticket.save!

    assert_in_delta(ticket.last_owner_update_at.to_i, ticket.updated_at.to_i, 1)

    ticket = Ticket.create!(
      title:         'assignment_timeout test 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'closed'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_nil(ticket.last_owner_update_at)

    travel 1.hour
    ticket.owner = @agent1
    ticket.save!

    assert_in_delta(ticket.last_owner_update_at.to_i, ticket.updated_at.to_i, 1)

    ticket = Ticket.create!(
      title:         'assignment_timeout test 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         @agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_in_delta(ticket.last_owner_update_at.to_i, ticket.updated_at.to_i, 1)

    ticket.owner_id = 1
    ticket.save!
    assert_nil(ticket.last_owner_update_at)

    ticket = Ticket.create!(
      title:         'assignment_timeout test 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         @agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'open'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_in_delta(ticket.last_owner_update_at.to_i, ticket.updated_at.to_i, 1)

    ticket.owner_id = 1
    ticket.save!
    assert_nil(ticket.last_owner_update_at)

    ticket = Ticket.create!(
      title:         'assignment_timeout test 2',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_nil(ticket.last_owner_update_at)

    travel 1.hour
    ticket.owner = @agent1
    ticket.save!

    assert_in_delta(ticket.last_owner_update_at.to_i, ticket.updated_at.to_i, 1)

    ticket = Ticket.create!(
      title:         'assignment_timeout test 2',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'closed'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_nil(ticket.last_owner_update_at)

    travel 1.hour
    ticket.owner = @agent1
    ticket.save!

    assert_in_delta(ticket.last_owner_update_at.to_i, ticket.updated_at.to_i, 1)

    ticket = Ticket.create!(
      title:         'assignment_timeout test 2',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         @agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_in_delta(ticket.last_owner_update_at.to_i, ticket.updated_at.to_i, 1)

    ticket.owner_id = 1
    ticket.save!
    assert_nil(ticket.last_owner_update_at)

    ticket = Ticket.create!(
      title:         'assignment_timeout test 2',
      group:         Group.lookup(name: 'Users'),
      owner:         @agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'closed'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_nil(ticket.last_owner_update_at)

    ticket.owner_id = 1
    ticket.save!
    assert_nil(ticket.last_owner_update_at)

  end

  test 'last_owner_update_at assignment_timeout check' do

    ticket1 = Ticket.create!(
      title:         'assignment_timeout test 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_nil(ticket1.last_owner_update_at)

    ticket2 = Ticket.create!(
      title:         'assignment_timeout test 2',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         @agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_in_delta(ticket2.last_owner_update_at.to_i, ticket2.updated_at.to_i, 1)

    ticket3 = Ticket.create!(
      title:         'assignment_timeout test 3',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         @agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'open'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_in_delta(ticket3.last_owner_update_at.to_i, ticket3.updated_at.to_i, 1)

    ticket4 = Ticket.create!(
      title:         'assignment_timeout test 4',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_nil(ticket4.last_owner_update_at)

    ticket5 = Ticket.create!(
      title:         'assignment_timeout test 5',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         @agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_in_delta(ticket5.last_owner_update_at.to_i, ticket5.updated_at.to_i, 1)

    travel 55.minutes
    Ticket.process_auto_unassign

    ticket1after = Ticket.find(ticket1.id)
    assert_nil(ticket1.last_owner_update_at)
    assert_equal(ticket1.updated_at.to_s, ticket1after.updated_at.to_s)

    ticket2after = Ticket.find(ticket2.id)
    assert_in_delta(ticket2.last_owner_update_at.to_i, ticket2after.last_owner_update_at.to_i, 1)
    assert_equal(ticket2.updated_at.to_s, ticket2after.updated_at.to_s)

    ticket3after = Ticket.find(ticket3.id)
    assert_in_delta(ticket3.last_owner_update_at.to_i, ticket3after.last_owner_update_at.to_i, 1)
    assert_equal(ticket3.updated_at.to_s, ticket3after.updated_at.to_s)

    ticket4after = Ticket.find(ticket4.id)
    assert_nil(ticket4.last_owner_update_at)
    assert_equal(ticket4.updated_at.to_s, ticket4after.updated_at.to_s)

    ticket5after = Ticket.find(ticket5.id)
    assert_equal(ticket5after.owner_id, @agent1.id)
    assert_equal(ticket5.updated_at.to_s, ticket5after.updated_at.to_s)

    travel 15.minutes
    Ticket.process_auto_unassign
    ticket_updated_at = Time.current

    ticket1after = Ticket.find(ticket1.id)
    assert_nil(ticket1.last_owner_update_at)
    assert_equal(ticket1.updated_at.to_s, ticket1after.updated_at.to_s)

    ticket2after = Ticket.find(ticket2.id)
    assert_nil(ticket2after.last_owner_update_at)
    assert_equal(ticket2after.owner_id, 1)
    assert_equal(ticket_updated_at.to_s, ticket2after.updated_at.to_s)

    ticket3after = Ticket.find(ticket3.id)
    assert_nil(ticket3after.last_owner_update_at)
    assert_equal(ticket3after.owner_id, 1)
    assert_equal(ticket_updated_at.to_s, ticket3after.updated_at.to_s)

    ticket4after = Ticket.find(ticket4.id)
    assert_nil(ticket4.last_owner_update_at)
    assert_equal(ticket4.updated_at.to_s, ticket4after.updated_at.to_s)

    ticket5after = Ticket.find(ticket5.id)
    assert_equal(ticket5after.owner_id, 1)
    assert_equal(ticket_updated_at.to_s, ticket5after.updated_at.to_s)

  end

end
