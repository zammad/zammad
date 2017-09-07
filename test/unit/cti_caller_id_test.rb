# encoding: utf-8
require 'test_helper'

class CtiCallerIdTest < ActiveSupport::TestCase

  setup do

    Ticket.destroy_all
    Cti::CallerId.destroy_all

    @agent1 = User.create_or_update(
      login: 'ticket-caller_id-agent1@example.com',
      firstname: 'CallerId',
      lastname: 'Agent1',
      email: 'ticket-caller_id-agent1@example.com',
      password: 'agentpw',
      active: true,
      phone: '+49 1111 222222',
      fax: '+49 1111 222223',
      mobile: '+49 1111 222223',
      note: 'Phone at home: +49 1111 222224',
      updated_by_id: 1,
      created_by_id: 1,
    )
    @agent2 = User.create_or_update(
      login: 'ticket-caller_id-agent2@example.com',
      firstname: 'CallerId',
      lastname: 'Agent2',
      email: 'ticket-caller_id-agent2@example.com',
      password: 'agentpw',
      phone: '+49 2222 222222',
      note: 'Phone at home: <b>+49 2222 222224</b>',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    @agent3 = User.create_or_update(
      login: 'ticket-caller_id-agent3@example.com',
      firstname: 'CallerId',
      lastname: 'Agent3',
      email: 'ticket-caller_id-agent3@example.com',
      password: 'agentpw',
      phone: '+49 2222 222222',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    @customer1 = User.create_or_update(
      login: 'ticket-caller_id-customer1@example.com',
      firstname: 'CallerId',
      lastname: 'Customer1',
      email: 'ticket-caller_id-customer1@example.com',
      password: 'customerpw',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

  end

  test '1 lookups' do

    Cti::CallerId.rebuild

    caller_ids = Cti::CallerId.lookup('491111222277')
    assert_equal(0, caller_ids.length)

    caller_ids = Cti::CallerId.lookup('491111222223')
    assert_equal(1, caller_ids.length)
    assert_equal(@agent1.id, caller_ids[0].user_id)
    assert_equal('known', caller_ids[0].level)

    caller_ids = Cti::CallerId.lookup('492222222222')
    assert_equal(2, caller_ids.length)
    assert_equal(@agent3.id, caller_ids[0].user_id)
    assert_equal('known', caller_ids[0].level)
    assert_equal(@agent2.id, caller_ids[1].user_id)
    assert_equal('known', caller_ids[1].level)

    # create ticket in group
    ticket1 = Ticket.create!(
      title: 'some caller id test 1',
      group: Group.lookup(name: 'Users'),
      customer: @customer1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    article1 = Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message\nFon (GEL): +49 111 366-1111 Mi-Fr
Fon (LIN): +49 222 6112222 Mo-Di
Mob: +49 333 8362222",
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer1.id,
      created_by_id: @customer1.id,
    )
    assert(ticket1)

    # create ticket in group
    ticket2 = Ticket.create!(
      title: 'some caller id test 2',
      group: Group.lookup(name: 'Users'),
      customer: @customer1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    article2 = Ticket::Article.create!(
      ticket_id: ticket2.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message\nFon (GEL): +49 111 111-1111 Mi-Fr
Fon (LIN): +49 222 1112222 Mo-Di
Mob: +49 333 1112222",
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    assert(ticket2)

    Cti::CallerId.rebuild

    caller_ids = Cti::CallerId.lookup('491111222277')
    assert_equal(0, caller_ids.length)

    caller_ids = Cti::CallerId.lookup('491111222223')
    assert_equal(1, caller_ids.length)
    assert_equal(@agent1.id, caller_ids[0].user_id)
    assert_equal('known', caller_ids[0].level)

    caller_ids = Cti::CallerId.lookup('492222222222')
    assert_equal(2, caller_ids.length)
    assert_equal(@agent3.id, caller_ids[0].user_id)
    assert_equal('known', caller_ids[0].level)
    assert_equal(@agent2.id, caller_ids[1].user_id)
    assert_equal('known', caller_ids[1].level)

    caller_ids = Cti::CallerId.lookup('492226112222')
    assert_equal(1, caller_ids.length)
    assert_equal(@customer1.id, caller_ids[0].user_id)
    assert_equal('maybe', caller_ids[0].level)

    caller_ids = Cti::CallerId.lookup('492221112222')
    assert_equal(0, caller_ids.length)

  end

  test '2 lookups' do

    Cti::CallerId.destroy_all

    Cti::CallerId.maybe_add(
      caller_id: '4999999999',
      level: 'maybe',
      user_id: 2,
      object: 'Ticket',
      o_id: 2,
    )

    Cti::CallerId.maybe_add(
      caller_id: '4912345678901',
      comment: 'Hairdresser Bob Smith, San Francisco',
      level: 'public',
      user_id: 2,
      object: 'GoYello',
      o_id: 1,
    )

    caller_ids = Cti::CallerId.lookup('4912345678901')
    assert_equal(1, caller_ids.length)
    assert_equal('public', caller_ids[0].level)
    assert_equal(2, caller_ids[0].user_id)
    assert_equal('Hairdresser Bob Smith, San Francisco', caller_ids[0].comment)

    Cti::CallerId.maybe_add(
      caller_id: '4912345678901',
      level: 'maybe',
      user_id: 2,
      object: 'Ticket',
      o_id: 2,
    )

    caller_ids = Cti::CallerId.lookup('4912345678901')
    assert_equal(1, caller_ids.length)
    assert_equal('maybe', caller_ids[0].level)
    assert_equal(2, caller_ids[0].user_id)
    assert_nil(caller_ids[0].comment)

    Cti::CallerId.maybe_add(
      caller_id: '4912345678901',
      level: 'maybe',
      user_id: 2,
      object: 'Ticket',
      o_id: 2,
    )

    caller_ids = Cti::CallerId.lookup('4912345678901')
    assert_equal(1, caller_ids.length)
    assert_equal('maybe', caller_ids[0].level)
    assert_equal(2, caller_ids[0].user_id)
    assert_nil(caller_ids[0].comment)

    user_id = User.find_by(login: 'ticket-caller_id-customer1@example.com').id

    Cti::CallerId.maybe_add(
      caller_id: '4912345678901',
      level: 'maybe',
      user_id: user_id,
      object: 'Ticket',
      o_id: 2,
    )

    caller_ids = Cti::CallerId.lookup('4912345678901')
    assert_equal(2, caller_ids.length)
    assert_equal('maybe', caller_ids[0].level)
    assert_equal(user_id, caller_ids[0].user_id)
    assert_nil(caller_ids[0].comment)
    assert_equal('maybe', caller_ids[1].level)
    assert_equal(2, caller_ids[1].user_id)
    assert_nil(caller_ids[1].comment)

    Cti::CallerId.maybe_add(
      caller_id: '4912345678901',
      level: 'known',
      user_id: user_id,
      object: 'User',
      o_id: 2,
    )

    caller_ids = Cti::CallerId.lookup('4912345678901')
    assert_equal(1, caller_ids.length)
    assert_equal('known', caller_ids[0].level)
    assert_equal(user_id, caller_ids[0].user_id)
    assert_nil(caller_ids[0].comment)

  end

  test '3 process - log' do

    ticket1 = Ticket.create!(
      title: 'some caller id test 1',
      group: Group.lookup(name: 'Users'),
      customer: @customer1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    article1 = Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message\nFon (GEL): +49 111 366-1111 Mi-Fr
Fon (LIN): +49 222 6112222 Mo-Di
Mob: +49 333 8362222",
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer1.id,
      created_by_id: @customer1.id,
    )
    assert(ticket1)
    ticket2 = Ticket.create!(
      title: 'some caller id test 2',
      group: Group.lookup(name: 'Users'),
      customer: @customer1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    article2 = Ticket::Article.create!(
      ticket_id: ticket2.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message\nFon (GEL): +49 111 366-1111 Mi-Fr
Fon (LIN): +49 222 6112222 Mo-Di
Mob: +49 333 8362222",
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer1.id,
      created_by_id: @customer1.id,
    )
    assert(ticket2)

    Cti::CallerId.rebuild

    Cti::Log.process(
      'cause' => '',
      'event' => 'newCall',
      'user' => 'user 1',
      'from' => '491113661111',
      'to' => '4930600000000',
      'callId' => '4991155921769858278-1',
      'direction' => 'in',
    )

    log = Cti::Log.log
    assert(log[:list])
    assert(log[:assets])
    assert(log[:list][0])
    assert_not(log[:list][1])
    assert(log[:list][0].preferences)
    assert(log[:list][0].preferences[:from])
    assert_equal(1, log[:list][0].preferences[:from].count)
    assert_equal(@customer1.id, log[:list][0].preferences[:from][0][:user_id])
    assert_equal('maybe', log[:list][0].preferences[:from][0][:level])

  end

end
