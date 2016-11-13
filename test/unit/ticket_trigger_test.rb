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
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
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
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket1 created')
    Ticket::Article.create(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], Tag.tag_list(object: 'Ticket', o_id: ticket1.id))

    Observer::Transaction.commit

    ticket1 = Ticket.lookup(id: ticket1.id)
    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w(aa kk), Tag.tag_list(object: 'Ticket', o_id: ticket1.id))
    article1 = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', article1.from)
    assert_match('nicole.braun@zammad.org', article1.to)
    assert_match('Thanks for your inquiry (some <b>title</b>  äöüß)!', article1.subject)
    assert_match('Braun<br>some &lt;b&gt;title&lt;/b&gt;', article1.body)
    assert_match('&gt; some message &lt;b&gt;note&lt;/b&gt;<br>&gt; new line', article1.body)
    assert_equal('text/html', article1.content_type)

    ticket1.priority = Ticket::Priority.lookup(name: '2 normal')
    ticket1.save

    Observer::Transaction.commit

    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w(aa kk), Tag.tag_list(object: 'Ticket', o_id: ticket1.id))

    ticket1.state = Ticket::State.lookup(name: 'open')
    ticket1.save

    Observer::Transaction.commit

    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('open', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w(aa kk), Tag.tag_list(object: 'Ticket', o_id: ticket1.id))

    ticket1.state = Ticket::State.lookup(name: 'new')
    ticket1.save

    Observer::Transaction.commit

    ticket1 = Ticket.lookup(id: ticket1.id)
    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(3, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w(aa kk), Tag.tag_list(object: 'Ticket', o_id: ticket1.id))
    article1 = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', article1.from)
    assert_match('nicole.braun@zammad.org', article1.to)
    assert_match('Thanks for your inquiry (some <b>title</b>  äöüß)!', article1.subject)
    assert_match('Braun<br>some &lt;b&gt;title&lt;/b&gt;', article1.body)
    assert_equal('text/html', article1.content_type)

    ticket2 = Ticket.create(
      title: "some title\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
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

    ticket3 = Ticket.create(
      title: "some <b>title</b>\n äöüß3",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket3, 'ticket3 created')
    Ticket::Article.create(
      ticket_id: ticket3.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_equal('some <b>title</b>  äöüß3', ticket3.title, 'ticket3.title verify')
    assert_equal('Users', ticket3.group.name, 'ticket3.group verify')
    assert_equal('new', ticket3.state.name, 'ticket3.state verify')
    assert_equal('2 normal', ticket3.priority.name, 'ticket3.priority verify')
    assert_equal(1, ticket3.articles.count, 'ticket3.articles verify')
    assert_equal([], Tag.tag_list(object: 'Ticket', o_id: ticket3.id))

    Observer::Transaction.commit

    ticket3 = Ticket.lookup(id: ticket3.id)
    assert_equal('some <b>title</b>  äöüß3', ticket3.title, 'ticket3.title verify')
    assert_equal('Users', ticket3.group.name, 'ticket3.group verify')
    assert_equal('new', ticket3.state.name, 'ticket3.state verify')
    assert_equal('3 high', ticket3.priority.name, 'ticket3.priority verify')
    assert_equal(2, ticket3.articles.count, 'ticket3.articles verify')
    assert_equal(%w(aa kk), Tag.tag_list(object: 'Ticket', o_id: ticket3.id))
    article3 = ticket3.articles.last
    assert_match('Zammad <zammad@localhost>', article3.from)
    assert_match('nicole.braun@zammad.org', article3.to)
    assert_match('Thanks for your inquiry (some <b>title</b>  äöüß3)!', article3.subject)
    assert_match('Braun<br>some &lt;b&gt;title&lt;/b&gt;', article3.body)
    assert_match('&gt; some message note<br>&gt; new line', article3.body)
    assert_no_match('&gt; some message &lt;b&gt;note&lt;/b&gt;<br>&gt; new line', article3.body)
    assert_equal('text/html', article3.content_type)

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
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
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
    article1 = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', article1.from)
    assert_match('nicole.braun@zammad.org', article1.to)
    assert_match('asdasdas', article1.subject)
    assert_match('dasdasdasd', article1.body)
    assert_equal('text/html', article1.content_type)

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
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
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

    # process mail with abuse@ (no auto response)
    content = IO.binread('test/fixtures/ticket_trigger/mail3.box')
    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, content)

    assert_equal('new', ticket_p.state.name)
    assert_equal(1, ticket_p.articles.count)

    Trigger.destroy_all
  end

  test '4 has changed' do
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
      login: 'ticket-has-changed-customer2@example.com',
      firstname: 'Notification',
      lastname: 'Customer2',
      email: 'ticket-has-changed-customer2@example.com',
      password: 'customerpw',
      active: true,
      organization_id: nil,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Agent')
    agent1 = User.create_or_update(
      login: 'agent-has-changed@example.com',
      firstname: 'Has Changed',
      lastname: 'Agent1',
      email: 'agent-has-changed@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    trigger1 = Trigger.create_or_update(
      name: 'owner update - to customer',
      condition: {
        'ticket.owner_id' => {
          'operator' => 'has changed',
          'pre_condition' => 'current_user.id',
          'value' => '',
          'value_completion' => '',
        }
      },
      perform: {
        'notification.email' => {
          'body' => '<p>The owner of ticket (Ticket##{ticket.number}) has changed.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
          'recipient' => 'ticket_customer',
          'subject' => 'Owner has changed (#{ticket.title})',
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
    assert_equal(1, ticket_p.articles.count)
    article_p = ticket_p.articles.last

    Observer::Transaction.commit

    ticket_p.owner = agent1
    ticket_p.save
    Observer::Transaction.commit
    assert_equal('aaäöüßad asd', ticket_p.title, 'ticket_p.title verify')
    assert_equal('Users', ticket_p.group.name, 'ticket_p.group verify')
    assert_equal('new', ticket_p.state.name, 'ticket_p.state verify')
    assert_equal('2 normal', ticket_p.priority.name, 'ticket_p.priority verify')
    assert_equal(2, ticket_p.articles.count, 'ticket_p.articles verify')

    #p ticket_p.articles.last.inspect
    article_p = ticket_p.articles.last
    assert_match('Owner has changed', article_p.subject)
    assert_match('Zammad <zammad@localhost>', article_p.from)
    assert_match('martin@example.com', article_p.to)
    assert_no_match('config\.', article_p.body)
    assert_match('http://zammad.example.com', article_p.body)
    assert_no_match('ticket.', article_p.body)
    assert_match(ticket_p.number, article_p.body)
    assert_equal('text/html', article_p.content_type)

    trigger1 = Trigger.create_or_update(
      name: 'owner update - to customer',
      condition: {
        'ticket.owner_id' => {
          'operator' => 'has changed',
          'pre_condition' => 'current_user.id',
          'value' => '',
          'value_completion' => '',
        },
        'ticket.priority_id' => {
          'operator' => 'is',
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
      },
      perform: {
        'notification.email' => {
          'body' => '<p>The owner of ticket (Ticket##{ticket.number}) has changed.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
          'recipient' => 'ticket_customer',
          'subject' => 'Owner has changed (#{ticket.title})',
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
    assert_equal(1, ticket_p.articles.count)
    article_p = ticket_p.articles.last

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.priority = Ticket::Priority.lookup(name: '1 low')
    ticket_p.save

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.priority = Ticket::Priority.lookup(name: '3 high')
    ticket_p.save

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.owner = agent1
    ticket_p.save

    Observer::Transaction.commit
    assert_equal('aaäöüßad asd', ticket_p.title, 'ticket_p.title verify')
    assert_equal('Users', ticket_p.group.name, 'ticket_p.group verify')
    assert_equal('new', ticket_p.state.name, 'ticket_p.state verify')
    assert_equal('3 high', ticket_p.priority.name, 'ticket_p.priority verify')
    assert_equal(2, ticket_p.articles.count, 'ticket_p.articles verify')

    #p ticket_p.articles.last.inspect
    article_p = ticket_p.articles.last
    assert_match('Owner has changed', article_p.subject)
    assert_match('Zammad <zammad@localhost>', article_p.from)
    assert_match('martin@example.com', article_p.to)
    assert_no_match('config\.', article_p.body)
    assert_match('http://zammad.example.com', article_p.body)
    assert_no_match('ticket.', article_p.body)
    assert_match(ticket_p.number, article_p.body)
    assert_equal('text/html', article_p.content_type)

    # should trigger
    trigger1 = Trigger.create_or_update(
      name: 'owner update - to customer',
      condition: {
        'ticket.owner_id' => {
          'operator' => 'has changed',
          'pre_condition' => 'current_user.id',
          'value' => '',
          'value_completion' => '',
        },
        'ticket.priority_id' => {
          'operator' => 'is',
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
        'ticket.action' => {
          'operator' => 'is not',
          'value' => 'create',
        },
      },
      perform: {
        'notification.email' => {
          'body' => '<p>The owner of ticket (Ticket##{ticket.number}) has changed.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
          'recipient' => 'ticket_customer',
          'subject' => 'Owner has changed (#{ticket.title})',
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
    assert_equal(1, ticket_p.articles.count)
    article_p = ticket_p.articles.last

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.priority = Ticket::Priority.lookup(name: '1 low')
    ticket_p.save

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.priority = Ticket::Priority.lookup(name: '3 high')
    ticket_p.save

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.owner = agent1
    ticket_p.save

    Observer::Transaction.commit
    assert_equal('aaäöüßad asd', ticket_p.title, 'ticket_p.title verify')
    assert_equal('Users', ticket_p.group.name, 'ticket_p.group verify')
    assert_equal('new', ticket_p.state.name, 'ticket_p.state verify')
    assert_equal('3 high', ticket_p.priority.name, 'ticket_p.priority verify')
    assert_equal(2, ticket_p.articles.count, 'ticket_p.articles verify')

    #p ticket_p.articles.last.inspect
    article_p = ticket_p.articles.last
    assert_match('Owner has changed', article_p.subject)
    assert_match('Zammad <zammad@localhost>', article_p.from)
    assert_match('martin@example.com', article_p.to)
    assert_no_match('config\.', article_p.body)
    assert_match('http://zammad.example.com', article_p.body)
    assert_no_match('ticket.', article_p.body)
    assert_match(ticket_p.number, article_p.body)
    assert_equal('text/html', article_p.content_type)

    # should not trigger
    trigger1 = Trigger.create_or_update(
      name: 'owner update - to customer',
      condition: {
        'ticket.owner_id' => {
          'operator' => 'has changed',
          'pre_condition' => 'current_user.id',
          'value' => '',
          'value_completion' => '',
        },
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'create',
        },
      },
      perform: {
        'notification.email' => {
          'body' => '<p>The owner of ticket (Ticket##{ticket.number}) has changed.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
          'recipient' => 'ticket_customer',
          'subject' => 'Owner has changed (#{ticket.title})',
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

    assert_equal(1, ticket_p.articles.count)

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.owner = agent1
    ticket_p.save

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    Trigger.destroy_all
  end

end
