# encoding: utf-8
require 'test_helper'

class TicketTriggerTest < ActiveSupport::TestCase
  test '1 basic' do
    trigger1 = Trigger.create_or_update(
      name: 'auto reply',
      condition: {
        'ticket.state_id' => {
          'operator' => 'is',
          'value' => Ticket::State.lookup(name: 'new').id.to_s,
        }
      },
      perform: {
        'notification.email' => {
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
        'ticket.tags' => {
          'operator' => 'add',
          'value' => 'aa, kk',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    trigger2 = Trigger.create_or_update(
      name: 'not matching',
      condition: {
        'ticket.state_id' => {
          'operator' => 'is',
          'value' => Ticket::State.lookup(name: 'closed').id.to_s,
        }
      },
      perform: {
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ticket1 = Ticket.create(
      title: "some <b>title</b>\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket1 created')

    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(0, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], Tag.tag_list(object: 'Ticket', o_id: ticket1.id))

    Observer::Transaction.commit

    ticket1 = Ticket.lookup(id: ticket1.id)
    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w(aa kk), Tag.tag_list(object: 'Ticket', o_id: ticket1.id))
    article1 = ticket1.articles.last
    assert_match('Thanks for your inquiry (some <b>title</b>  äöüß)!', article1.subject)
    assert_match('Braun<br>some &lt;b&gt;title&lt;/b&gt;', article1.body)
    assert_equal('text/html', article1.content_type)

    ticket1.priority = Ticket::Priority.lookup(name: '2 normal')
    ticket1.save

    Observer::Transaction.commit

    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w(aa kk), Tag.tag_list(object: 'Ticket', o_id: ticket1.id))

    ticket1.state = Ticket::State.lookup(name: 'open')
    ticket1.save

    Observer::Transaction.commit

    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('open', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w(aa kk), Tag.tag_list(object: 'Ticket', o_id: ticket1.id))

    ticket1.state = Ticket::State.lookup(name: 'new')
    ticket1.save

    Observer::Transaction.commit

    ticket1 = Ticket.lookup(id: ticket1.id)
    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w(aa kk), Tag.tag_list(object: 'Ticket', o_id: ticket1.id))

    ticket2 = Ticket.create(
      title: "some title\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'open'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket2, 'ticket2 created')

    assert_equal('some title  äöüß', ticket2.title, 'ticket2.title verify')
    assert_equal('Users', ticket2.group.name, 'ticket2.group verify')
    assert_equal('open', ticket2.state.name, 'ticket2.state verify')
    assert_equal('2 normal', ticket2.priority.name, 'ticket2.priority verify')
    assert_equal(0, ticket2.articles.count, 'ticket2.articles verify')
    assert_equal([], Tag.tag_list(object: 'Ticket', o_id: ticket2.id))

    Observer::Transaction.commit

    ticket2 = Ticket.lookup(id: ticket2.id)
    assert_equal('some title  äöüß', ticket2.title, 'ticket2.title verify')
    assert_equal('Users', ticket2.group.name, 'ticket2.group verify')
    assert_equal('open', ticket2.state.name, 'ticket2.state verify')
    assert_equal('2 normal', ticket2.priority.name, 'ticket2.priority verify')
    assert_equal(0, ticket2.articles.count, 'ticket2.articles verify')
    assert_equal([], Tag.tag_list(object: 'Ticket', o_id: ticket2.id))

    Trigger.destroy_all
  end

  test '2 actions - create' do
    trigger1 = Trigger.create_or_update(
      name: 'auto reply',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'create',
        },
        'ticket.state_id' => {
          'operator' => 'is',
          'value' => Ticket::State.lookup(name: 'new').id.to_s,
        }
      },
      perform: {
        'notification.email' => {
          'body' => 'dasdasdasd',
          'recipient' => 'ticket_customer',
          'subject' => 'asdasdas',
        },
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ticket1 = Ticket.create(
      title: "some title\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket1 created')

    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(0, ticket1.articles.count, 'ticket1.articles verify')

    Observer::Transaction.commit

    ticket1 = Ticket.lookup(id: ticket1.id)
    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')

    ticket1.priority = Ticket::Priority.lookup(name: '2 normal')
    ticket1.save

    Observer::Transaction.commit

    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')

    ticket1.state = Ticket::State.lookup(name: 'open')
    ticket1.save

    Observer::Transaction.commit

    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('open', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')

    ticket1.state = Ticket::State.lookup(name: 'new')
    ticket1.save

    Observer::Transaction.commit

    ticket1 = Ticket.lookup(id: ticket1.id)
    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')

    Trigger.destroy_all
  end

  test '2 actions - update' do
    trigger1 = Trigger.create_or_update(
      name: 'auto reply',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'update',
        },
        'ticket.state_id' => {
          'operator' => 'is',
          'value' => Ticket::State.lookup(name: 'new').id.to_s,
        }
      },
      perform: {
        'notification.email' => {
          'body' => 'dasdasdasd',
          'recipient' => 'ticket_customer',
          'subject' => 'asdasdas',
        },
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ticket1 = Ticket.create(
      title: "some title\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket1 created')

    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(0, ticket1.articles.count, 'ticket1.articles verify')

    Observer::Transaction.commit

    ticket1 = Ticket.lookup(id: ticket1.id)
    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(0, ticket1.articles.count, 'ticket1.articles verify')

    ticket1.priority = Ticket::Priority.lookup(name: '2 normal')
    ticket1.save

    Observer::Transaction.commit

    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(0, ticket1.articles.count, 'ticket1.articles verify')

    ticket1.state = Ticket::State.lookup(name: 'open')
    ticket1.save

    Observer::Transaction.commit

    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('open', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(0, ticket1.articles.count, 'ticket1.articles verify')

    ticket1.state = Ticket::State.lookup(name: 'new')
    ticket1.save

    Observer::Transaction.commit

    ticket1 = Ticket.lookup(id: ticket1.id)
    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')

    Trigger.destroy_all
  end

end
