# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket: #last_owner_update_at' do # rubocop:disable RSpec/DescribeClass
  let(:group) do
    Group.create_or_update(
      name:               'LastOwnerUpdate',
      email_address:      create(:email_address),
      assignment_timeout: 60,
      updated_by_id:      1,
      created_by_id:      1,
    )
  end
  let(:agent1) do
    User.create_or_update(
      login:         'ticket-assignment_timeout-agent1@example.com',
      firstname:     'Overview',
      lastname:      'Agent1',
      email:         'ticket-assignment_timeout-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         Role.where(name: 'Agent'),
      groups:        Group.all,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  before do
    group
    agent1
  end

  it 'is set for owned tickets in active states and cleared when moved to a closed or pending state', :aggregate_failures do
    ticket = Ticket.create!(
      title:         'assignment_timeout test by state 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(ticket.last_owner_update_at.to_i).to be_within(1).of(ticket.updated_at.to_i)

    ticket.state = Ticket::State.lookup(name: 'closed')
    ticket.save!
    expect(ticket.last_owner_update_at).to be_nil

    ticket = Ticket.create!(
      title:         'assignment_timeout test by state 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'pending reminder'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(ticket.last_owner_update_at).to be_nil

    ticket.state = Ticket::State.lookup(name: 'open')
    ticket.save!

    expect(ticket.last_owner_update_at.to_i).to be_within(1).of(ticket.updated_at.to_i)
  end

  it 'is unaffected by article replies from customers or agents', :aggregate_failures do
    ticket = Ticket.create!(
      title:         'assignment_timeout test by state 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'open'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(ticket.last_owner_update_at.to_i).to be_within(1).of(ticket.updated_at.to_i)

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

    expect(ticket.last_owner_update_at.to_i).to be_within(1).of(ticket_last_owner_update_at.to_i)

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
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
    )

    ticket_last_owner_update_at = Time.zone.now
    ticket.reload

    expect(ticket.last_owner_update_at.to_i).to be_within(1).of(ticket_last_owner_update_at.to_i)
  end

  it 'is set or cleared for each owner (re)assignment, independently per group and state', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
    ticket = Ticket.create!(
      title:         'assignment_timeout test 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(ticket.last_owner_update_at).to be_nil

    travel 1.hour
    ticket.owner = agent1
    ticket.save!

    expect(ticket.last_owner_update_at.to_i).to be_within(1).of(ticket.updated_at.to_i)

    ticket = Ticket.create!(
      title:         'assignment_timeout test 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'closed'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(ticket.last_owner_update_at).to be_nil

    travel 1.hour
    ticket.owner = agent1
    ticket.save!

    expect(ticket.last_owner_update_at.to_i).to be_within(1).of(ticket.updated_at.to_i)

    ticket = Ticket.create!(
      title:         'assignment_timeout test 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    expect(ticket.last_owner_update_at.to_i).to be_within(1).of(ticket.updated_at.to_i)

    ticket.owner_id = 1
    ticket.save!
    expect(ticket.last_owner_update_at).to be_nil

    ticket = Ticket.create!(
      title:         'assignment_timeout test 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'open'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(ticket.last_owner_update_at.to_i).to be_within(1).of(ticket.updated_at.to_i)

    ticket.owner_id = 1
    ticket.save!
    expect(ticket.last_owner_update_at).to be_nil

    ticket = Ticket.create!(
      title:         'assignment_timeout test 2',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(ticket.last_owner_update_at).to be_nil

    travel 1.hour
    ticket.owner = agent1
    ticket.save!

    expect(ticket.last_owner_update_at.to_i).to be_within(1).of(ticket.updated_at.to_i)

    ticket = Ticket.create!(
      title:         'assignment_timeout test 2',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'closed'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(ticket.last_owner_update_at).to be_nil

    travel 1.hour
    ticket.owner = agent1
    ticket.save!

    expect(ticket.last_owner_update_at.to_i).to be_within(1).of(ticket.updated_at.to_i)

    ticket = Ticket.create!(
      title:         'assignment_timeout test 2',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    expect(ticket.last_owner_update_at.to_i).to be_within(1).of(ticket.updated_at.to_i)

    ticket.owner_id = 1
    ticket.save!
    expect(ticket.last_owner_update_at).to be_nil

    ticket = Ticket.create!(
      title:         'assignment_timeout test 2',
      group:         Group.lookup(name: 'Users'),
      owner:         agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'closed'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(ticket.last_owner_update_at).to be_nil

    ticket.owner_id = 1
    ticket.save!
    expect(ticket.last_owner_update_at).to be_nil
  end

  it 'clears the owner and last_owner_update_at once the group assignment_timeout elapses, but only for group tickets with a non-default owner', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
    ticket1 = Ticket.create!(
      title:         'assignment_timeout test 1',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(ticket1.last_owner_update_at).to be_nil

    ticket2 = Ticket.create!(
      title:         'assignment_timeout test 2',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    expect(ticket2.last_owner_update_at.to_i).to be_within(1).of(ticket2.updated_at.to_i)

    ticket3 = Ticket.create!(
      title:         'assignment_timeout test 3',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'open'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    expect(ticket3.last_owner_update_at.to_i).to be_within(1).of(ticket3.updated_at.to_i)

    ticket4 = Ticket.create!(
      title:         'assignment_timeout test 4',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    expect(ticket4.last_owner_update_at).to be_nil

    ticket5 = Ticket.create!(
      title:         'assignment_timeout test 5',
      group:         Group.lookup(name: 'LastOwnerUpdate'),
      owner:         agent1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    expect(ticket5.last_owner_update_at.to_i).to be_within(1).of(ticket5.updated_at.to_i)

    travel 55.minutes
    Ticket.process_auto_unassign

    ticket1after = Ticket.find(ticket1.id)
    expect(ticket1.last_owner_update_at).to be_nil
    expect(ticket1after.updated_at.to_s).to eq(ticket1.updated_at.to_s)

    ticket2after = Ticket.find(ticket2.id)
    expect(ticket2after.last_owner_update_at.to_i).to be_within(1).of(ticket2.last_owner_update_at.to_i)
    expect(ticket2after.updated_at.to_s).to eq(ticket2.updated_at.to_s)

    ticket3after = Ticket.find(ticket3.id)
    expect(ticket3after.last_owner_update_at.to_i).to be_within(1).of(ticket3.last_owner_update_at.to_i)
    expect(ticket3after.updated_at.to_s).to eq(ticket3.updated_at.to_s)

    ticket4after = Ticket.find(ticket4.id)
    expect(ticket4.last_owner_update_at).to be_nil
    expect(ticket4after.updated_at.to_s).to eq(ticket4.updated_at.to_s)

    ticket5after = Ticket.find(ticket5.id)
    expect(ticket5after.owner_id).to eq(agent1.id)
    expect(ticket5after.updated_at.to_s).to eq(ticket5.updated_at.to_s)

    travel 15.minutes
    Ticket.process_auto_unassign
    ticket_updated_at = Time.current

    ticket1after = Ticket.find(ticket1.id)
    expect(ticket1.last_owner_update_at).to be_nil
    expect(ticket1after.updated_at.to_s).to eq(ticket1.updated_at.to_s)

    ticket2after = Ticket.find(ticket2.id)
    expect(ticket2after.last_owner_update_at).to be_nil
    expect(ticket2after.owner_id).to eq(1)
    expect(ticket2after.updated_at.to_s).to eq(ticket_updated_at.to_s)

    ticket3after = Ticket.find(ticket3.id)
    expect(ticket3after.last_owner_update_at).to be_nil
    expect(ticket3after.owner_id).to eq(1)
    expect(ticket3after.updated_at.to_s).to eq(ticket_updated_at.to_s)

    ticket4after = Ticket.find(ticket4.id)
    expect(ticket4.last_owner_update_at).to be_nil
    expect(ticket4after.updated_at.to_s).to eq(ticket4.updated_at.to_s)

    ticket5after = Ticket.find(ticket5.id)
    expect(ticket5after.owner_id).to eq(1)
    expect(ticket5after.updated_at.to_s).to eq(ticket_updated_at.to_s)
  end
end
