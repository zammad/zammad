# encoding: utf-8
require 'test_helper'

class CtiCallerIdTest < ActiveSupport::TestCase

  test '1 parse possible phone numbers in text' do
    text = "some text\ntest 123"
    result = []
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '0049 1234 123456789'
    result = ['491234123456789']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '022 1234567'
    result = ['49221234567']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '0271233211'
    result = ['49271233211']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '021-233-9123'
    result = ['49212339123']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '09 123 32112'
    result = ['49912332112']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '021 2331231'
    result = ['49212331231']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '021 321123123'
    result = ['4921321123123']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '622 32281'
    result = ['4962232281']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '5754321'
    result = ['495754321']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '092213212'
    result = ['4992213212']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '(09)1234321'
    result = ['4991234321']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '+49 30 53 00 00 000'
    result = ['4930530000000']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '+49 160 0000000'
    result = ['491600000000']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '+49 (0) 30 60 00 00 00-0'
    result = ['4930600000000']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '0043 (0) 30 60 00 00 00-0'
    result = ['4330600000000']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '0043 30 60 00 00 00-0'
    result = ['4330600000000']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = '1-888-407-4747'
    result = ['18884074747']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = 'Lorem ipsum dolor sit amet, consectetuer +49 (0) 30 60 00 00 00-0 adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec pede justo, fringilla vel.'
    result = ['4930600000000']
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = "GS Oberalteich\nTelefon  09422 1000 Telefax 09422 805000\nE-Mail:  "
    result = %w(4994221000 499422805000)
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = 'Tel +41 81 288 63 93 / +41 76 346 72 14 ...'
    result = %w(41812886393 41763467214)
    assert_equal(result, Cti::CallerId.parse_text(text))

    text = "P: +1 (949) 431 0000\nF: +1 (949) 431 0001\nW: http://znuny"
    result = %w(19494310000 19494310001)
    assert_equal(result, Cti::CallerId.parse_text(text))

  end

  test '2 lookups' do

    Ticket.destroy_all
    Cti::CallerId.destroy_all

    agent1 = User.create_or_update(
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
    agent2 = User.create_or_update(
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
    agent3 = User.create_or_update(
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

    customer1 = User.create_or_update(
      login: 'ticket-caller_id-customer1@example.com',
      firstname: 'CallerId',
      lastname: 'Customer1',
      email: 'ticket-caller_id-customer1@example.com',
      password: 'customerpw',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    Cti::CallerId.rebuild

    caller_ids = Cti::CallerId.lookup('491111222277')
    assert_equal(0, caller_ids.count)

    caller_ids = Cti::CallerId.lookup('491111222223')
    assert_equal(1, caller_ids.count)
    assert_equal(agent1.id, caller_ids[0].user_id)
    assert_equal('known', caller_ids[0].level)

    caller_ids = Cti::CallerId.lookup('492222222222')
    assert_equal(2, caller_ids.count)
    assert_equal(agent3.id, caller_ids[0].user_id)
    assert_equal('known', caller_ids[0].level)
    assert_equal(agent2.id, caller_ids[1].user_id)
    assert_equal('known', caller_ids[1].level)

    # create ticket in group
    ticket1 = Ticket.create(
      title: 'some caller id test 1',
      group: Group.lookup(name: 'Users'),
      customer: customer1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
    )
    article1 = Ticket::Article.create(
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
      updated_by_id: customer1.id,
      created_by_id: customer1.id,
    )
    assert(ticket1)

    # create ticket in group
    ticket2 = Ticket.create(
      title: 'some caller id test 2',
      group: Group.lookup(name: 'Users'),
      customer: customer1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
    )
    article2 = Ticket::Article.create(
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
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
    )
    assert(ticket2)

    Cti::CallerId.rebuild

    caller_ids = Cti::CallerId.lookup('491111222277')
    assert_equal(0, caller_ids.count)

    caller_ids = Cti::CallerId.lookup('491111222223')
    assert_equal(1, caller_ids.count)
    assert_equal(agent1.id, caller_ids[0].user_id)
    assert_equal('known', caller_ids[0].level)

    caller_ids = Cti::CallerId.lookup('492222222222')
    assert_equal(2, caller_ids.count)
    assert_equal(agent3.id, caller_ids[0].user_id)
    assert_equal('known', caller_ids[0].level)
    assert_equal(agent2.id, caller_ids[1].user_id)
    assert_equal('known', caller_ids[1].level)

    caller_ids = Cti::CallerId.lookup('492226112222')
    assert_equal(1, caller_ids.count)
    assert_equal(customer1.id, caller_ids[0].user_id)
    assert_equal('maybe', caller_ids[0].level)

    caller_ids = Cti::CallerId.lookup('492221112222')
    assert_equal(0, caller_ids.count)

  end

end
