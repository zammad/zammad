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

  test '3 auto replys' do
    roles = Role.where(name: 'Customer')
    customer1 = User.create_or_update(
      login: 'postmaster@example.com',
      firstname: 'Notification',
      lastname: 'Customer1',
      email: 'postmaster@example.com',
      password: 'customerpw',
      active: true,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    customer2 = User.create_or_update(
      login: 'ticket-auto-reply-customer2@example.com',
      firstname: 'Notification',
      lastname: 'Customer2',
      email: 'ticket-auto-reply-customer2@example.com',
      password: 'customerpw',
      active: true,
      organization_id: nil,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )

    trigger1 = Trigger.create_or_update(
      name: 'auto reply - new ticket',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'create',
        },
        'ticket.state_id' => {
          'operator' => 'is not',
          'value' => Ticket::State.lookup(name: 'closed').id,
        },
        'article.type_id' => {
          'operator' => 'is',
          'value' => [
            Ticket::Article::Type.lookup(name: 'email').id,
            Ticket::Article::Type.lookup(name: 'phone').id,
            Ticket::Article::Type.lookup(name: 'web').id,
          ],
        },
      },
      perform: {
        'notification.email' => {
          'body' => '<p>Your request (Ticket##{ticket.number}) has been received and will be reviewed by our support staff.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry (#{ticket.title})',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    trigger2 = Trigger.create_or_update(
      name: 'auto reply (on follow up of tickets)',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'update',
        },
        'article.sender_id' => {
          'operator' => 'is',
          'value' => Ticket::Article::Sender.lookup(name: 'Customer').id,
        },
        'article.type_id' => {
          'operator' => 'is',
          'value' => [
            Ticket::Article::Type.lookup(name: 'email').id,
            Ticket::Article::Type.lookup(name: 'phone').id,
            Ticket::Article::Type.lookup(name: 'web').id,
          ],
        },
      },
      perform: {
        'notification.email' => {
          'body' => '<p>Your follow up for (#{config.ticket_hook}##{ticket.number}) has been received and will be reviewed by our support staff.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your follow up (#{ticket.title})',
        },
      },
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    trigger3 = Trigger.create_or_update(
      name: 'not matching',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'create',
        },
        'ticket.state_id' => {
          'operator' => 'is',
          'value' => Ticket::State.lookup(name: 'closed').id.to_s,
        }
      },
      perform: {
        'notification.email' => {
          'body' => '2some text<br>#{ticket.customer.lastname}<br>#{ticket.title}',
          'recipient' => 'ticket_customer',
          'subject' => '2Thanks for your inquiry (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    # process mail without Precedence header
    content = IO.binread('test/fixtures/ticket_trigger/mail1.box')
    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, content)

    assert_equal('aaäöüßad asd', ticket_p.title)
    assert_equal('Users', ticket_p.group.name)
    assert_equal('new', ticket_p.state.name)
    assert_equal(2, ticket_p.articles.count)
    article_p = ticket_p.articles.last
    assert_match('Thanks for your inquiry (aaäöüßad asd)', article_p.subject)
    assert_match('Zammad <zammad@localhost>', article_p.from)
    assert_no_match('config\.', article_p.body)
    assert_match('http://zammad.example.com', article_p.body)
    assert_no_match('ticket.', article_p.body)
    assert_match(ticket_p.number, article_p.body)
    assert_equal('text/html', article_p.content_type)

    ticket_p.priority = Ticket::Priority.lookup(name: '2 normal')
    ticket_p.save
    Observer::Transaction.commit
    assert_equal('aaäöüßad asd', ticket_p.title, 'ticket_p.title verify')
    assert_equal('Users', ticket_p.group.name, 'ticket_p.group verify')
    assert_equal('new', ticket_p.state.name, 'ticket_p.state verify')
    assert_equal('2 normal', ticket_p.priority.name, 'ticket_p.priority verify')
    assert_equal(2, ticket_p.articles.count, 'ticket_p.articles verify')

    article_p = Ticket::Article.create(
      ticket_id: ticket_p.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message note',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit
    assert_equal('aaäöüßad asd', ticket_p.title, 'ticket_p.title verify')
    assert_equal('Users', ticket_p.group.name, 'ticket_p.group verify')
    assert_equal('new', ticket_p.state.name, 'ticket_p.state verify')
    assert_equal('2 normal', ticket_p.priority.name, 'ticket_p.priority verify')
    assert_equal(3, ticket_p.articles.count, 'ticket_p.articles verify')

    article_p = Ticket::Article.create(
      ticket_id: ticket_p.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message note',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit
    assert_equal('aaäöüßad asd', ticket_p.title, 'ticket_p.title verify')
    assert_equal('Users', ticket_p.group.name, 'ticket_p.group verify')
    assert_equal('new', ticket_p.state.name, 'ticket_p.state verify')
    assert_equal('2 normal', ticket_p.priority.name, 'ticket_p.priority verify')
    assert_equal(4, ticket_p.articles.count, 'ticket_p.articles verify')

    article_p = Ticket::Article.create(
      ticket_id: ticket_p.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message note',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit
    assert_equal('aaäöüßad asd', ticket_p.title, 'ticket_p.title verify')
    assert_equal('Users', ticket_p.group.name, 'ticket_p.group verify')
    assert_equal('new', ticket_p.state.name, 'ticket_p.state verify')
    assert_equal('2 normal', ticket_p.priority.name, 'ticket_p.priority verify')
    assert_equal(6, ticket_p.articles.count, 'ticket_p.articles verify')

    article_p = ticket_p.articles.last
    assert_match('Thanks for your follow up (aaäöüßad asd)', article_p.subject)
    assert_match('Zammad <zammad@localhost>', article_p.from)
    assert_no_match('config\.', article_p.body)
    assert_match('http://zammad.example.com', article_p.body)
    assert_no_match('ticket.', article_p.body)
    assert_match(ticket_p.number, article_p.body)
    assert_equal('text/html', article_p.content_type)

    ticket_p.state = Ticket::State.lookup(name: 'open')
    ticket_p.save
    article_p = Ticket::Article.create(
      ticket_id: ticket_p.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message note',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit
    assert_equal('aaäöüßad asd', ticket_p.title, 'ticket_p.title verify')
    assert_equal('Users', ticket_p.group.name, 'ticket_p.group verify')
    assert_equal('open', ticket_p.state.name, 'ticket_p.state verify')
    assert_equal('2 normal', ticket_p.priority.name, 'ticket_p.priority verify')
    assert_equal(8, ticket_p.articles.count, 'ticket_p.articles verify')

    article_p = ticket_p.articles.last
    assert_match('Thanks for your follow up (aaäöüßad asd)', article_p.subject)
    assert_match('Zammad <zammad@localhost>', article_p.from)
    assert_no_match('config\.', article_p.body)
    assert_match('http://zammad.example.com', article_p.body)
    assert_no_match('ticket.', article_p.body)
    assert_match(ticket_p.number, article_p.body)
    assert_equal('text/html', article_p.content_type)

    # process mail without Precedence header
    content = IO.binread('test/fixtures/ticket_trigger/mail1.box')
    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, content)

    assert_equal('new', ticket_p.state.name)
    assert_equal(2, ticket_p.articles.count)

    # process mail with Precedence header (no auto response)
    content = IO.binread('test/fixtures/ticket_trigger/mail2.box')
    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, content)

    assert_equal('new', ticket_p.state.name)
    assert_equal(1, ticket_p.articles.count)

    Trigger.destroy_all
  end

end
