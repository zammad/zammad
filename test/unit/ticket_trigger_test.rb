require 'test_helper'

class TicketTriggerTest < ActiveSupport::TestCase

  setup do
    Setting.set('ticket_trigger_recursive', true)
  end

  test '1 basic' do
    trigger1 = Trigger.create_or_update(
      name: 'aaa loop check',
      condition: {
        'article.subject' => {
          'operator' => 'contains',
          'value' => 'Thanks for your inquiry',
        },
      },
      perform: {
        'ticket.tags' => {
          'operator' => 'add',
          'value' => 'should_not_loop',
        },
        'notification.email' => {
          'body' => 'some lala',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry - loop check - only once (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    trigger2 = Trigger.create_or_update(
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

    trigger3 = Trigger.create_or_update(
      name: 'auto tag 1',
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
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
        'ticket.tags' => {
          'operator' => 'remove',
          'value' => 'kk',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    trigger4 = Trigger.create_or_update(
      name: 'auto tag 2',
      condition: {
        'ticket.state_id' => {
          'operator' => 'is',
          'value' => Ticket::State.lookup(name: 'new').id.to_s,
        }
      },
      perform: {
        'ticket.tags' => {
          'operator' => 'add',
          'value' => 'abc',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    trigger5 = Trigger.create_or_update(
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

    trigger6 = Trigger.create_or_update(
      name: 'zzz last',
      condition: {
        'article.subject' => {
          'operator' => 'contains',
          'value' => 'some subject 1234',
        },
      },
      perform: {
        'ticket.tags' => {
          'operator' => 'add',
          'value' => 'article_create_trigger',
        },
        'notification.email' => {
          'body' => 'some lala',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry - 1234 check (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: "some <b>title</b>\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
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

    ticket1.reload
    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(3, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w[aa kk should_not_loop abc], ticket1.tag_list)

    article1 = ticket1.articles.second
    assert_match('Zammad <zammad@localhost>', article1.from)
    assert_match('nicole.braun@zammad.org', article1.to)
    assert_match('Thanks for your inquiry (some <b>title</b>  äöüß)!', article1.subject)
    assert_match('Braun<br>some &lt;b&gt;title&lt;/b&gt;', article1.body)
    assert_match('&gt; some message &lt;b&gt;note&lt;/b&gt;<br>&gt; new line', article1.body)
    assert_equal('text/html', article1.content_type)

    article1 = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', article1.from)
    assert_match('nicole.braun@zammad.org', article1.to)
    assert_match('Thanks for your inquiry - loop check - only once (some <b>title</b>  äöüß)!', article1.subject)
    assert_match('some lala', article1.body)
    assert_equal('text/html', article1.content_type)

    ticket1.priority = Ticket::Priority.lookup(name: '2 normal')
    ticket1.save!
    Observer::Transaction.commit

    ticket1.reload
    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(3, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w[aa kk should_not_loop abc], ticket1.tag_list)

    ticket1.state = Ticket::State.lookup(name: 'open')
    ticket1.save!

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('open', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(3, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w[aa kk should_not_loop abc], ticket1.tag_list)

    ticket1.state = Ticket::State.lookup(name: 'new')
    ticket1.save!

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(3, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w[aa should_not_loop abc], ticket1.tag_list)

    ticket2 = Ticket.create!(
      title: "some title\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      state: Ticket::State.lookup(name: 'open'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_equal('some title  äöüß', ticket2.title, 'ticket2.title verify')
    assert_equal('Users', ticket2.group.name, 'ticket2.group verify')
    assert_equal('open', ticket2.state.name, 'ticket2.state verify')
    assert_equal('2 normal', ticket2.priority.name, 'ticket2.priority verify')
    assert_equal(0, ticket2.articles.count, 'ticket2.articles verify')
    assert_equal([], ticket2.tag_list)

    Observer::Transaction.commit

    ticket2.reload
    assert_equal('some title  äöüß', ticket2.title, 'ticket2.title verify')
    assert_equal('Users', ticket2.group.name, 'ticket2.group verify')
    assert_equal('open', ticket2.state.name, 'ticket2.state verify')
    assert_equal('2 normal', ticket2.priority.name, 'ticket2.priority verify')
    assert_equal(0, ticket2.articles.count, 'ticket2.articles verify')
    assert_equal([], ticket2.tag_list)

    ticket3 = Ticket.create!(
      title: "some <b>title</b>\n äöüß3",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket3, 'ticket3 created')

    Ticket::Article.create!(
      ticket_id: ticket3.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject 1234',
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
    assert_equal([], ticket3.tag_list)

    Observer::Transaction.commit

    ticket3.reload
    assert_equal('some <b>title</b>  äöüß3', ticket3.title, 'ticket3.title verify')
    assert_equal('Users', ticket3.group.name, 'ticket3.group verify')
    assert_equal('new', ticket3.state.name, 'ticket3.state verify')
    assert_equal('3 high', ticket3.priority.name, 'ticket3.priority verify')
    assert_equal(4, ticket3.articles.count, 'ticket3.articles verify')
    assert_equal(%w[aa kk should_not_loop abc article_create_trigger], ticket3.tag_list)
    article3 = ticket3.articles[1]
    assert_match('Zammad <zammad@localhost>', article3.from)
    assert_match('nicole.braun@zammad.org', article3.to)
    assert_match('Thanks for your inquiry (some <b>title</b>  äöüß3)!', article3.subject)
    assert_match('Braun<br>some &lt;b&gt;title&lt;/b&gt;', article3.body)
    assert_match('&gt; some message note<br>&gt; new line', article3.body)
    assert_no_match('&gt; some message &lt;b&gt;note&lt;/b&gt;<br>&gt; new line', article3.body)
    assert_equal('text/html', article3.content_type)
    article3 = ticket3.articles[2]
    assert_match('Zammad <zammad@localhost>', article3.from)
    assert_match('nicole.braun@zammad.org', article3.to)
    assert_match('Thanks for your inquiry - loop check - only once (some <b>title</b>', article3.subject)
    assert_match('some lala', article3.body)
    assert_equal('text/html', article3.content_type)
    article4 = ticket3.articles[3]
    assert_match('Zammad <zammad@localhost>', article4.from)
    assert_match('nicole.braun@zammad.org', article4.to)
    assert_match('Thanks for your inquiry - 1234 check (some <b>title</b>  äöüß3)!', article4.subject)
    assert_equal('text/html', article4.content_type)

    Ticket::Article.create!(
      ticket_id: ticket3.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject - not 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit

    ticket3.reload
    assert_equal('some <b>title</b>  äöüß3', ticket3.title, 'ticket3.title verify')
    assert_equal('Users', ticket3.group.name, 'ticket3.group verify')
    assert_equal('new', ticket3.state.name, 'ticket3.state verify')
    assert_equal('3 high', ticket3.priority.name, 'ticket3.priority verify')
    assert_equal(5, ticket3.articles.count, 'ticket3.articles verify')
    assert_equal(%w[aa should_not_loop abc article_create_trigger], ticket3.tag_list)

    Ticket::Article.create!(
      ticket_id: ticket3.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject NOT 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit

    ticket3.reload
    assert_equal('some <b>title</b>  äöüß3', ticket3.title, 'ticket3.title verify')
    assert_equal('Users', ticket3.group.name, 'ticket3.group verify')
    assert_equal('new', ticket3.state.name, 'ticket3.state verify')
    assert_equal('3 high', ticket3.priority.name, 'ticket3.priority verify')
    assert_equal(6, ticket3.articles.count, 'ticket3.articles verify')
    assert_equal(%w[aa should_not_loop abc article_create_trigger], ticket3.tag_list)

    Ticket::Article.create!(
      ticket_id: ticket3.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit

    ticket3.reload
    assert_equal('some <b>title</b>  äöüß3', ticket3.title, 'ticket3.title verify')
    assert_equal('Users', ticket3.group.name, 'ticket3.group verify')
    assert_equal('new', ticket3.state.name, 'ticket3.state verify')
    assert_equal('3 high', ticket3.priority.name, 'ticket3.priority verify')
    assert_equal(9, ticket3.articles.count, 'ticket3.articles verify')
    assert_equal(%w[aa should_not_loop abc article_create_trigger], ticket3.tag_list)
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

    ticket1 = Ticket.create!(
      title: "some title\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(0, ticket1.articles.count, 'ticket1.articles verify')

    Observer::Transaction.commit

    ticket1.reload
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
    ticket1.save!

    Observer::Transaction.commit

    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')

    ticket1.state = Ticket::State.lookup(name: 'open')
    ticket1.save!

    Observer::Transaction.commit

    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('open', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')

    ticket1.state = Ticket::State.lookup(name: 'new')
    ticket1.save!

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
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

    ticket1 = Ticket.create!(
      title: "some title\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(0, ticket1.articles.count, 'ticket1.articles verify')

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(0, ticket1.articles.count, 'ticket1.articles verify')

    ticket1.priority = Ticket::Priority.lookup(name: '2 normal')
    ticket1.save!

    Observer::Transaction.commit

    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(0, ticket1.articles.count, 'ticket1.articles verify')

    ticket1.state = Ticket::State.lookup(name: 'open')
    ticket1.save!

    Observer::Transaction.commit

    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('open', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(0, ticket1.articles.count, 'ticket1.articles verify')

    ticket1.state = Ticket::State.lookup(name: 'new')
    ticket1.save!

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
  end

  test '3 auto replys' do
    roles = Role.where(name: 'Customer')
    customer1 = User.create_or_update(
      login: 'postmaster@example.com',
      firstname: 'Trigger',
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
      firstname: 'Trigger',
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
    content = File.read(Rails.root.join('test', 'data', 'ticket_trigger', 'mail1.box'))
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
    ticket_p.save!
    Observer::Transaction.commit
    assert_equal('aaäöüßad asd', ticket_p.title, 'ticket_p.title verify')
    assert_equal('Users', ticket_p.group.name, 'ticket_p.group verify')
    assert_equal('new', ticket_p.state.name, 'ticket_p.state verify')
    assert_equal('2 normal', ticket_p.priority.name, 'ticket_p.priority verify')
    assert_equal(2, ticket_p.articles.count, 'ticket_p.articles verify')

    article_p = Ticket::Article.create!(
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

    article_p = Ticket::Article.create!(
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

    article_p = Ticket::Article.create!(
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
    ticket_p.save!
    article_p = Ticket::Article.create!(
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
    content = File.read(Rails.root.join('test', 'data', 'ticket_trigger', 'mail1.box'))
    ticket_p1, article_p1, user_p1, mail = Channel::EmailParser.new.process({}, content)

    assert_not_equal(ticket_p.id, ticket_p1.id)
    assert_equal('new', ticket_p1.state.name)
    assert_equal(2, ticket_p1.articles.count)

    # process mail with Precedence header (no auto response)
    content = File.read(Rails.root.join('test', 'data', 'ticket_trigger', 'mail2.box'))
    ticket_p2, article_p2, user_p2, mail = Channel::EmailParser.new.process({}, content)

    assert_not_equal(ticket_p.id, ticket_p1.id)
    assert_not_equal(ticket_p.id, ticket_p2.id)
    assert_not_equal(ticket_p1.id, ticket_p2.id)
    assert_equal('new', ticket_p2.state.name)
    assert_equal(1, ticket_p2.articles.count)

    # process mail with abuse@ (no auto response)
    content = File.read(Rails.root.join('test', 'data', 'ticket_trigger', 'mail3.box'))
    ticket_p3, article_p3, user_p3, mail = Channel::EmailParser.new.process({}, content)

    assert_not_equal(ticket_p.id, ticket_p1.id)
    assert_not_equal(ticket_p.id, ticket_p2.id)
    assert_not_equal(ticket_p.id, ticket_p3.id)
    assert_not_equal(ticket_p1.id, ticket_p2.id)
    assert_not_equal(ticket_p1.id, ticket_p3.id)
    assert_not_equal(ticket_p2.id, ticket_p1.id)
    assert_not_equal(ticket_p2.id, ticket_p3.id)
    assert_equal('new', ticket_p3.state.name)
    assert_equal(1, ticket_p3.articles.count)
  end

  test '4 has changed' do
    roles = Role.where(name: 'Customer')
    customer1 = User.create_or_update(
      login: 'postmaster@example.com',
      firstname: 'Trigger',
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
      firstname: 'Trigger',
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
    groups = Group.where(name: 'Users')
    roles = Role.where(name: 'Agent')
    agent1 = User.create_or_update(
      login: 'agent-has-changed@example.com',
      firstname: 'Has Changed',
      lastname: 'Agent1',
      email: 'agent-has-changed@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
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
    content = File.read(Rails.root.join('test', 'data', 'ticket_trigger', 'mail1.box'))
    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, content)

    assert_equal('aaäöüßad asd', ticket_p.title)
    assert_equal('Users', ticket_p.group.name)
    assert_equal('new', ticket_p.state.name)
    assert_equal(1, ticket_p.articles.count)
    article_p = ticket_p.articles.last

    Observer::Transaction.commit

    ticket_p.owner = agent1
    ticket_p.save!
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
    content = File.read(Rails.root.join('test', 'data', 'ticket_trigger', 'mail1.box'))
    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, content)

    assert_equal('aaäöüßad asd', ticket_p.title)
    assert_equal('Users', ticket_p.group.name)
    assert_equal('new', ticket_p.state.name)
    assert_equal(1, ticket_p.articles.count)
    article_p = ticket_p.articles.last

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.priority = Ticket::Priority.lookup(name: '1 low')
    ticket_p.save!

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.priority = Ticket::Priority.lookup(name: '3 high')
    ticket_p.save!

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.owner = agent1
    ticket_p.save!

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
    content = File.read(Rails.root.join('test', 'data', 'ticket_trigger', 'mail1.box'))
    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, content)

    assert_equal('aaäöüßad asd', ticket_p.title)
    assert_equal('Users', ticket_p.group.name)
    assert_equal('new', ticket_p.state.name)
    assert_equal(1, ticket_p.articles.count)
    article_p = ticket_p.articles.last

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.priority = Ticket::Priority.lookup(name: '1 low')
    ticket_p.save!

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.priority = Ticket::Priority.lookup(name: '3 high')
    ticket_p.save!

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.owner = agent1
    ticket_p.save!

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
    content = File.read(Rails.root.join('test', 'data', 'ticket_trigger', 'mail1.box'))
    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, content)

    assert_equal(1, ticket_p.articles.count)

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)

    ticket_p.owner = agent1
    ticket_p.save!

    Observer::Transaction.commit
    assert_equal(1, ticket_p.articles.count)
  end

  test '5 notify owner' do
    trigger1 = Trigger.create_or_update(
      name: 'aaa notify mail',
      condition: {
        'ticket.state_id' => {
          'operator' => 'is',
          'value' => Ticket::State.all.pluck(:id),
        },
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'update',
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some lala',
          'recipient' => 'ticket_owner',
          'subject' => 'CC NOTE (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    groups = Group.where(name: 'Users')
    roles = Role.where(name: 'Agent')
    agent = User.create_or_update(
      login: 'agent@example.com',
      firstname: 'Trigger',
      lastname: 'Agent1',
      email: 'agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: 'test 123',
      owner: agent,
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
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

    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    Observer::Transaction.commit

    assert_equal(1, ticket1.articles.count)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'update',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'update',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit

    assert_equal(3, ticket1.articles.count)

    trigger1 = Trigger.create_or_update(
      name: 'aaa notify mail 2',
      condition: {
        'ticket.state_id' => {
          'operator' => 'is',
          'value' => Ticket::State.all.pluck(:id),
        },
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'update',
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some lala',
          'recipient' => 'ticket_owner',
          'subject' => 'CC NOTE (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'update',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'update',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit

    assert_equal(6, ticket1.articles.count)
  end

  test '6 owner auto assignment' do
    trigger1 = Trigger.create_or_update(
      name: 'aaa auto assignment',
      condition: {
        'ticket.owner_id' => {
          'operator' => 'is',
          'pre_condition' => 'not_set',
          'value' => '',
          'value_completion' => '',
        },
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'update',
        },
      },
      perform: {
        'ticket.owner_id' => {
          'pre_condition' => 'current_user.id',
          'value' => '',
          'value_completion' => '',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    groups = Group.where(name: 'Users')
    roles = Role.where(name: 'Agent')
    agent = User.create_or_update(
      login: 'agent@example.com',
      firstname: 'Trigger',
      lastname: 'Agent1',
      email: 'agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: 'test 123',
      #owner: agent,
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
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
    Observer::Transaction.commit

    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(1, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent.id
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'update',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'update',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
    )
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent.id
    ticket1.owner_id = 1
    ticket1.save!
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(1, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

  end

  test '6.1 owner auto assignment based on organization' do
    trigger1 = Trigger.create_or_update(
      name: 'aaa auto assignment',
      condition: {
        'ticket.organization_id' => {
          'operator' => 'is not',
          'pre_condition' => 'not_set',
          'value' => '',
          'value_completion' => '',
        },
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'update',
        },
      },
      perform: {
        'ticket.owner_id' => {
          'pre_condition' => 'current_user.id',
          'value' => '',
          'value_completion' => '',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    roles = Role.where(name: 'Agent')
    groups = Group.where(name: 'Users')
    agent = User.create_or_update(
      login: 'agent@example.com',
      firstname: 'Trigger',
      lastname: 'Agent1',
      email: 'agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    customer = User.create_or_update(
      login: 'customer@example.com',
      firstname: 'Trigger',
      lastname: 'Customer1',
      email: 'customer@example.com',
      password: 'customerpw',
      vip: true,
      active: true,
      roles: roles,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: 'test 123',
      group: Group.lookup(name: 'Users'),
      customer: customer,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
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
    Observer::Transaction.commit

    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(1, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    ticket1.update!(customer: User.lookup(email: 'nicole.braun@zammad.org') )

    UserInfo.current_user_id = agent.id
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'update',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'update',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
    )
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)
  end

  test '6.2 owner auto assignment based on organization' do
    trigger1 = Trigger.create_or_update(
      name: 'aaa auto assignment',
      condition: {
        'ticket.organization_id' => {
          'operator' => 'is',
          'pre_condition' => 'not_set',
          'value' => '',
          'value_completion' => '',
        },
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'update',
        },
      },
      perform: {
        'ticket.owner_id' => {
          'pre_condition' => 'current_user.id',
          'value' => '',
          'value_completion' => '',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    groups = Group.where(name: 'Users')
    roles = Role.where(name: 'Agent')
    agent = User.create_or_update(
      login: 'agent@example.com',
      firstname: 'Trigger',
      lastname: 'Agent1',
      email: 'agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    customer = User.create_or_update(
      login: 'customer@example.com',
      firstname: 'Trigger',
      lastname: 'Customer1',
      email: 'customer@example.com',
      password: 'customerpw',
      vip: true,
      active: true,
      roles: roles,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: 'test 123',
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
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
    Observer::Transaction.commit

    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(1, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    ticket1.update!(customer: customer )

    UserInfo.current_user_id = agent.id
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'update',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'update',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
    )
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)
  end

  test '7 owner auto assignment' do
    trigger1 = Trigger.create_or_update(
      name: 'aaa auto assignment',
      condition: {
        'ticket.owner_id' => {
          'operator' => 'is',
          'pre_condition' => 'not_set',
          'value' => '',
          'value_completion' => '',
        },
        'article.type_id' => {
          'operator' => 'is',
          'value' => Ticket::Article::Type.find_by(name: 'note'),
        },
        'article.sender_id' => {
          'operator' => 'is',
          'value' => Ticket::Article::Sender.find_by(name: 'Agent'),
        },
      },
      perform: {
        'ticket.owner_id' => {
          'pre_condition' => 'current_user.id',
          'value' => '',
          'value_completion' => '',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    groups = Group.where(name: 'Users')
    roles = Role.where(name: 'Agent')
    agent1 = User.create_or_update(
      login: 'agent@example.com',
      firstname: 'Trigger',
      lastname: 'Agent1',
      email: 'agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent2 = User.create_or_update(
      login: 'agent@example.com',
      firstname: 'Trigger',
      lastname: 'Agent2',
      email: 'agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: 'test 123',
      #owner: agent,
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
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
    Observer::Transaction.commit

    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(1, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent1.id
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'update',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'update',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
    )
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent1.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent1.id
    ticket1.owner_id = 1
    ticket1.save!
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(1, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent1.id
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'update',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'update',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'note'),
    )
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(1, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(3, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent2.id
    ticket1.owner_id = agent2.id
    ticket1.save!
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent2.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(3, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent1.id
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'update',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'update',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
    )
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent1.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(4, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)
  end

  test '8 owner auto assignment' do
    trigger1 = Trigger.create_or_update(
      name: 'aaa auto assignment',
      condition: {
        'ticket.owner_id' => {
          'operator' => 'is',
          'pre_condition' => 'not_set',
          'value' => '',
          'value_completion' => '',
        },
        'ticket.priority_id' => {
          'operator' => 'has changed',
          'pre_condition' => '',
          'value' => '2',
          'value_completion' => '',
        },
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'update',
        },
      },
      perform: {
        'ticket.owner_id' => {
          'pre_condition' => 'current_user.id',
          'value' => '',
          'value_completion' => '',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    groups = Group.where(name: 'Users')
    roles = Role.where(name: 'Agent')
    agent = User.create_or_update(
      login: 'agent@example.com',
      firstname: 'Trigger',
      lastname: 'Agent1',
      email: 'agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: 'test 123',
      #owner: agent,
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
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
    Observer::Transaction.commit

    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(1, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent.id
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'update',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'update',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
    )
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(1, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent.id
    ticket1.priority = Ticket::Priority.find_by(name: '1 low')
    ticket1.save!
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('1 low', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent.id
    ticket1.owner_id = 1
    ticket1.save!
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(1, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('1 low', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent.id
    ticket1.owner_id = agent.id
    ticket1.save!
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('1 low', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)
  end

  test '9 vip priority set' do
    trigger1 = Trigger.create_or_update(
      name: 'aaa vip priority',
      condition: {
        'customer.vip' => {
          'operator' => 'is',
          'value' => true,
        },
      },
      perform: {
        'ticket.priority_id' => {
          'value' => Ticket::Priority.find_by(name: '3 high').id,
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    groups = Group.where(name: 'Users')
    roles = Role.where(name: 'Agent')
    agent = User.create_or_update(
      login: 'agent@example.com',
      firstname: 'Trigger',
      lastname: 'Agent1',
      email: 'agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    customer = User.create_or_update(
      login: 'customer@example.com',
      firstname: 'Trigger',
      lastname: 'Customer1',
      email: 'customer@example.com',
      password: 'customerpw',
      vip: true,
      active: true,
      roles: roles,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: 'test 123',
      owner: agent,
      customer: customer,
      group: Group.lookup(name: 'Users'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
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

    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal(customer.id, ticket1.customer_id, 'ticket1.customer_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal(customer.id, ticket1.customer_id, 'ticket1.customer_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    customer.vip = false
    customer.save!

    ticket2 = Ticket.create!(
      title: 'test 123',
      owner: agent,
      customer: customer,
      group: Group.lookup(name: 'Users'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket2.id,
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

    assert_equal('test 123', ticket2.title, 'ticket2.title verify')
    assert_equal('Users', ticket2.group.name, 'ticket2.group verify')
    assert_equal(agent.id, ticket2.owner_id, 'ticket2.owner_id verify')
    assert_equal(customer.id, ticket2.customer_id, 'ticket2.customer_id verify')
    assert_equal('new', ticket2.state.name, 'ticket2.state verify')
    assert_equal('2 normal', ticket2.priority.name, 'ticket2.priority verify')
    assert_equal(1, ticket2.articles.count, 'ticket2.articles verify')
    assert_equal([], ticket2.tag_list)

    Observer::Transaction.commit

    ticket2.reload
    assert_equal('test 123', ticket2.title, 'ticket2.title verify')
    assert_equal('Users', ticket2.group.name, 'ticket2.group verify')
    assert_equal(agent.id, ticket2.owner_id, 'ticket2.owner_id verify')
    assert_equal(customer.id, ticket2.customer_id, 'ticket2.customer_id verify')
    assert_equal('new', ticket2.state.name, 'ticket2.state verify')
    assert_equal('2 normal', ticket2.priority.name, 'ticket2.priority verify')
    assert_equal(1, ticket2.articles.count, 'ticket2.articles verify')
    assert_equal([], ticket2.tag_list)

  end

  test '10 owner auto assignment notify to customer' do
    trigger1 = Trigger.create_or_update(
      name: 'aaa auto assignment',
      condition: {
        'ticket.owner_id' => {
          'operator' => 'has changed',
          'pre_condition' => '',
          'value' => '2',
          'value_completion' => '',
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some lala',
          'recipient' => 'ticket_customer',
          'subject' => 'NEW OWNER (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    groups = Group.where(name: 'Users')
    roles = Role.where(name: 'Agent')
    agent1 = User.create_or_update(
      login: 'agent1@example.com',
      firstname: 'Trigger',
      lastname: 'Agent1',
      email: 'agent1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent2 = User.create_or_update(
      login: 'agent2@example.com',
      firstname: 'Trigger',
      lastname: 'Agent2',
      email: 'agent2@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: 'test 123',
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
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
    Observer::Transaction.commit

    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(1, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent1.id
    ticket1.owner_id = agent1.id
    ticket1.save!
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent1.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent1.id
    ticket1.owner_id = agent1.id
    ticket1.save!
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent1.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent1.id
    ticket1.owner_id = agent2.id
    ticket1.save!
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent2.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(3, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

  end

  test '11 notify to customer on public note' do
    trigger1 = Trigger.create_or_update(
      name: 'aaa notify to customer on public note',
      condition: {
        'article.internal' => {
          'operator' => 'is',
          'value' => 'false',
        },
        'article.sender_id' => {
          'operator' => 'is',
          'value' => Ticket::Article::Sender.lookup(name: 'Agent').id,
        },
        'article.type_id' => {
          'operator' => 'is',
          'value' => [
            Ticket::Article::Type.lookup(name: 'note').id,
          ],
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some lala',
          'recipient' => 'ticket_customer',
          'subject' => 'UPDATE (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    groups = Group.where(name: 'Users')
    roles = Role.where(name: 'Agent')
    agent = User.create_or_update(
      login: 'agent@example.com',
      firstname: 'Trigger',
      lastname: 'Agent1',
      email: 'agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    customer = User.create_or_update(
      login: 'customer@example.com',
      firstname: 'Trigger',
      lastname: 'Customer1',
      email: 'customer@example.com',
      password: 'customerpw',
      vip: true,
      active: true,
      roles: roles,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: 'test 123',
      owner: agent,
      customer: customer,
      group: Group.lookup(name: 'Users'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
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

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal(customer.id, ticket1.customer_id, 'ticket1.customer_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: true,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal(customer.id, ticket1.customer_id, 'ticket1.customer_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(3, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    Ticket::Article.create!(
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
    Observer::Transaction.commit

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal(customer.id, ticket1.customer_id, 'ticket1.customer_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(5, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    ticket1.priority = Ticket::Priority.find_by(name: '3 high')
    ticket1.save!
    article = Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: true,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal(customer.id, ticket1.customer_id, 'ticket1.customer_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(6, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    article.internal = false
    article.save!
    Observer::Transaction.commit

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal(customer.id, ticket1.customer_id, 'ticket1.customer_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(6, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: true,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal(customer.id, ticket1.customer_id, 'ticket1.customer_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(7, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)
  end

  test '12 notify on owner change' do
    trigger1 = Trigger.create_or_update(
      name: 'aaa notify to customer on public note',
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
          'body' => 'some lala',
          'recipient' => 'ticket_customer',
          'subject' => 'UPDATE (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    Trigger.create_or_update(
      name: 'auto reply (on new tickets)',
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
        'article.sender_id' => {
          'operator' => 'is',
          'value' => Ticket::Article::Sender.lookup(name: 'Customer').id,
        },
      },
      perform: {
        'notification.email' => {
          'body' => '<div>Your request <b>(#{config.ticket_hook}#{ticket.number})</b> has been received and will be reviewed by our support staff.</div>
    <br/>
    <div>To provide additional information, please reply to this email or click on the following link (for initial login, please request a new password):
    <a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
    </div>
    <br/>
    <div>Your #{config.product_name} Team</div>
    <br/>
    <div><i><a href="https://zammad.com">Zammad</a>, your customer support system</i></div>',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry (#{ticket.title})',
        },
      },
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    Trigger.create_or_update(
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
          'body' => '<div>Your follow up for <b>(#{config.ticket_hook}#{ticket.number})</b> has been received and will be reviewed by our support staff.</div>
    <br/>
    <div>To provide additional information, please reply to this email or click on the following link:
    <a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
    </div>
    <br/>
    <div>Your #{config.product_name} Team</div>
    <br/>
    <div><i><a href="https://zammad.com">Zammad</a>, your customer support system</i></div>',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your follow up (#{ticket.title})',
        },
      },
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    groups = Group.where(name: 'Users')
    roles = Role.where(name: 'Agent')
    agent = User.create_or_update(
      login: 'agent@example.com',
      firstname: 'Trigger',
      lastname: 'Agent1',
      email: 'agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    customer = User.create_or_update(
      login: 'customer@example.com',
      firstname: 'Trigger',
      lastname: 'Customer1',
      email: 'customer@example.com',
      password: 'customerpw',
      vip: true,
      active: true,
      roles: roles,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: 'test 123',
      #owner: agent,
      customer: customer,
      group: Group.lookup(name: 'Users'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'web'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(1, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal(customer.id, ticket1.customer_id, 'ticket1.customer_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent.id
    ticket1.owner_id = agent.id
    ticket1.save!
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal(customer.id, ticket1.customer_id, 'ticket1.customer_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(3, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'web'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(agent.id, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal(customer.id, ticket1.customer_id, 'ticket1.customer_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(5, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    UserInfo.current_user_id = agent.id
    ticket1.owner_id = 1
    ticket1.save!
    Observer::Transaction.commit
    UserInfo.current_user_id = nil

    ticket1.reload
    assert_equal('test 123', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal(1, ticket1.owner_id, 'ticket1.owner_id verify')
    assert_equal(customer.id, ticket1.customer_id, 'ticket1.customer_id verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(6, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

  end

  test '1 empty condition should not create errors' do
    assert_raises(Exception) do
      trigger_empty = Trigger.create_or_update(
        name: 'aaa loop check',
        condition: {
          'ticket.number' => {
            'operator' => 'contains',
            'value'    => '',
          },
        },
        perform: {
          'notification.email' => {
            'body' => 'some lala',
            'recipient' => 'ticket_customer',
            'subject' => 'Thanks for your inquiry - loop check (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active: true,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end
  end

  test 'article_last_sender trigger -> reply_to' do
    trigger = Trigger.create_or_update(
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
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'article_last_sender',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ticket1 = Ticket.create!(
      title: "some <b>title</b>\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient+from@example.com',
      reply_to: 'some_recipient+reply_to@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('new', ticket1.state.name, 'ticket1.state new')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    auto_response = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', auto_response.from)
    assert_match('some_recipient+reply_to@example.com', auto_response.to)
  end

  test 'article_last_sender trigger -> from' do
    trigger = Trigger.create_or_update(
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
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'article_last_sender',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ticket1 = Ticket.create!(
      title: "some <b>title</b>\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender+from@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('new', ticket1.state.name, 'ticket1.state new')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    auto_response = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', auto_response.from)
    assert_match('some_sender+from@example.com', auto_response.to)
  end

  test 'article_last_sender trigger -> origin_by_id' do
    trigger = Trigger.create_or_update(
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
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'article_last_sender',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    customer1 = User.create_or_update(
      login: 'customer+origin_by_id@example.com',
      firstname: 'Trigger',
      lastname: 'Customer1',
      email: 'customer+origin_by_id@example.com',
      password: 'customerpw',
      active: true,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket1 = Ticket.create!(
      title: "some <b>title</b>\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      origin_by_id: customer1.id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('new', ticket1.state.name, 'ticket1.state new')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    auto_response = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', auto_response.from)
    assert_match('customer+origin_by_id@example.com', auto_response.to)
  end

  test 'article_last_sender trigger -> created_by_id' do
    trigger = Trigger.create_or_update(
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
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'article_last_sender',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    customer1 = User.create_or_update(
      login: 'customer+created_by_id@example.com',
      firstname: 'Trigger',
      lastname: 'Customer1',
      email: 'customer+created_by_id@example.com',
      password: 'customerpw',
      active: true,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket1 = Ticket.create!(
      title: "some <b>title</b>\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: customer1.id,
      created_by_id: customer1.id,
    )

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('new', ticket1.state.name, 'ticket1.state new')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    auto_response = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', auto_response.from)
    assert_match('customer+created_by_id@example.com', auto_response.to)
  end

  test 'multiple recipients owner_id, article_last_sender(reply_to) trigger' do
    trigger = Trigger.create_or_update(
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
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => %w[ticket_owner article_last_sender],
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    admin = User.create_or_update(
      login: 'admin+owner_recipient@example.com',
      firstname: 'Role',
      lastname: "Admin#{name}",
      email: 'admin+owner_recipient@example.com',
      password: 'adminpw',
      active: true,
      roles: Role.where(name: %w[Admin Agent]),
      groups: Group.where(name: 'Users'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket1 = Ticket.create!(
      title: "some <b>title</b>\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      owner_id: admin.id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient+from@example.com',
      reply_to: 'some_recipient+reply_to@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('new', ticket1.state.name, 'ticket1.state new')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    auto_response = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', auto_response.from)
    assert_match('some_recipient+reply_to@example.com', auto_response.to)
    assert_match('admin+owner_recipient@example.com', auto_response.to)
  end

  test 'article_last_sender trigger -> invalid reply_to' do
    trigger = Trigger.create_or_update(
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
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'article_last_sender',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ticket1 = Ticket.create!(
      title: "some <b>title</b>\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient+from@example.com',
      reply_to: 'Blub blub blub some_recipient+reply_to@example',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('new', ticket1.state.name, 'ticket1.state new')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
  end

  test '2 loop check' do
    trigger1 = Trigger.create_or_update(
      name: 'aaa loop check',
      condition: {
        'ticket.state_id' => {
          'operator' => 'is',
          'value' => Ticket::State.all.pluck(:id),
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
          'body' => 'some lala',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry - loop check (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: 'loop try 1',
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_loop_sender@example.com',
      to: 'some_loop_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket1.reload
    assert_equal(1, ticket1.articles.count)

    Observer::Transaction.commit
    ticket1.reload
    assert_equal(2, ticket1.articles.count)

    ticket1.priority = Ticket::Priority.lookup(name: '2 normal')
    ticket1.save!

    Observer::Transaction.commit
    ticket1.reload
    assert_equal(2, ticket1.articles.count)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_loop_sender@example.com',
      to: 'some_loop_recipient@example.com',
      subject: 'some subject 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    ticket1.reload
    assert_equal(4, ticket1.articles.count)
    assert_equal('some_loop_sender@example.com', ticket1.articles[2].from)
    assert_equal('nicole.braun@zammad.org', ticket1.articles[3].to)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_loop_sender@example.com',
      to: 'some_loop_recipient@example.com',
      subject: 'some subject 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    ticket1.reload
    assert_equal(6, ticket1.articles.count)
    assert_equal('some_loop_sender@example.com', ticket1.articles[4].from)
    assert_equal('nicole.braun@zammad.org', ticket1.articles[5].to)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_loop_sender@example.com',
      to: 'some_loop_recipient@example.com',
      subject: 'some subject 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    ticket1.reload
    assert_equal(8, ticket1.articles.count)
    assert_equal('some_loop_sender@example.com', ticket1.articles[6].from)
    assert_equal('nicole.braun@zammad.org', ticket1.articles[7].to)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_loop_sender@example.com',
      to: 'some_loop_recipient@example.com',
      subject: 'some subject 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    ticket1.reload
    assert_equal(10, ticket1.articles.count)
    assert_equal('some_loop_sender@example.com', ticket1.articles[8].from)
    assert_equal('nicole.braun@zammad.org', ticket1.articles[9].to)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_loop_sender@example.com',
      to: 'some_loop_recipient@example.com',
      subject: 'some subject 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    ticket1.reload
    assert_equal(12, ticket1.articles.count)
    assert_equal('some_loop_sender@example.com', ticket1.articles[10].from)
    assert_equal('nicole.braun@zammad.org', ticket1.articles[11].to)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_loop_sender@example.com',
      to: 'some_loop_recipient@example.com',
      subject: 'some subject 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    ticket1.reload
    assert_equal(14, ticket1.articles.count)
    assert_equal('some_loop_sender@example.com', ticket1.articles[12].from)
    assert_equal('nicole.braun@zammad.org', ticket1.articles[13].to)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_loop_sender@example.com',
      to: 'some_loop_recipient@example.com',
      subject: 'some subject 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    ticket1.reload
    assert_equal(16, ticket1.articles.count)
    assert_equal('some_loop_sender@example.com', ticket1.articles[14].from)
    assert_equal('nicole.braun@zammad.org', ticket1.articles[15].to)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_loop_sender@example.com',
      to: 'some_loop_recipient@example.com',
      subject: 'some subject 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    ticket1.reload
    assert_equal(18, ticket1.articles.count)
    assert_equal('some_loop_sender@example.com', ticket1.articles[16].from)
    assert_equal('nicole.braun@zammad.org', ticket1.articles[17].to)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_loop_sender@example.com',
      to: 'some_loop_recipient@example.com',
      subject: 'some subject 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    ticket1.reload
    assert_equal(20, ticket1.articles.count)
    assert_equal('some_loop_sender@example.com', ticket1.articles[18].from)
    assert_equal('nicole.braun@zammad.org', ticket1.articles[19].to)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_loop_sender@example.com',
      to: 'some_loop_recipient@example.com',
      subject: 'some subject 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    ticket1.reload
    assert_equal(21, ticket1.articles.count)
    assert_equal('some_loop_sender@example.com', ticket1.articles[20].from)

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_loop_sender@example.com',
      to: 'some_loop_recipient@example.com',
      subject: 'some subject 1234',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message <b>note</b><br>new line',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    ticket1.reload
    assert_equal(22, ticket1.articles.count)
    assert_equal('some_loop_sender@example.com', ticket1.articles[21].from)

  end

  test '3 invalid condition' do
    trigger1 = Trigger.create_or_update(
      name: 'aaa loop check',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'create',
        },
      },
      perform: {
        'ticket.tags' => {
          'operator' => 'add',
          'value' => 'xxx',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    trigger1.update_column(:condition, {
                             'ticket.action' => {
                               'operator' => 'is',
                               'value' => 'create',
                             },
                             'ticket.first_response_at' => {
                               'operator' => 'before (absolute)',
                               'value' => 'invalid invalid 4',
                             },
                           })
    assert_equal('invalid invalid 4', trigger1.condition['ticket.first_response_at']['value'])

    trigger2 = Trigger.create_or_update(
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

    ticket1 = Ticket.create!(
      title: "some <b>title</b>\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
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

    ticket1.reload
    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('some <b>title</b>  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('3 high', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w[aa kk], ticket1.tag_list)
    article1 = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', article1.from)
    assert_match('nicole.braun@zammad.org', article1.to)
    assert_match('Thanks for your inquiry (some <b>title</b>  äöüß)!', article1.subject)
    assert_match('Braun<br>some &lt;b&gt;title&lt;/b&gt;', article1.body)
    assert_match('&gt; some message &lt;b&gt;note&lt;/b&gt;<br>&gt; new line', article1.body)
    assert_equal('text/html', article1.content_type)

  end

  test '4 tag based auto response' do
    trigger1 = Trigger.create_or_update(
      name: '100 add tag if sender 1',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'create',
        },
        'article.from' => {
          'operator' => 'contains',
          'value' => 'sender1',
        },
      },
      perform: {
        'ticket.tags' => {
          'operator' => 'add',
          'value' => 'sender1',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    trigger2 = Trigger.create_or_update(
      name: '200 add tag if sender 2',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'create',
        },
        'article.from' => {
          'operator' => 'contains',
          'value' => 'sender2',
        },
      },
      perform: {
        'ticket.tags' => {
          'operator' => 'add',
          'value' => 'sender2',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    trigger3 = Trigger.create_or_update(
      name: '300 auto reply',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'create',
        },
        'ticket.state_id' => {
          'operator' => 'is',
          'value' => Ticket::State.lookup(name: 'new').id.to_s,
        },
        'ticket.tags' => {
          #'operator' => 'contains one not',
          'operator' => 'contains all not',
          'value' => 'sender1, sender2',
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: 'test 1',
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'sender1@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1.reload
    assert_equal('test 1', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)
    Observer::Transaction.commit
    ticket1.reload
    assert_equal('test 1', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w[sender1], ticket1.tag_list)

    ticket2 = Ticket.create!(
      title: 'test 2',
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket2.id,
      from: 'sender2@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket2.reload
    assert_equal('test 2', ticket2.title, 'ticket2.title verify')
    assert_equal('Users', ticket2.group.name, 'ticket2.group verify')
    assert_equal('new', ticket2.state.name, 'ticket2.state verify')
    assert_equal('2 normal', ticket2.priority.name, 'ticket2.priority verify')
    assert_equal(1, ticket2.articles.count, 'ticket2.articles verify')
    assert_equal([], ticket2.tag_list)

    Observer::Transaction.commit

    ticket2.reload
    assert_equal('test 2', ticket2.title, 'ticket2.title verify')
    assert_equal('Users', ticket2.group.name, 'ticket2.group verify')
    assert_equal('new', ticket2.state.name, 'ticket2.state verify')
    assert_equal('2 normal', ticket2.priority.name, 'ticket2.priority verify')
    assert_equal(1, ticket2.articles.count, 'ticket2.articles verify')
    assert_equal(%w[sender2], ticket2.tag_list)

    ticket3 = Ticket.create!(
      title: 'test 3',
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket3, 'ticket3 created')
    Ticket::Article.create!(
      ticket_id: ticket3.id,
      from: 'sender0@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message <b>note</b>\nnew line",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket3.reload
    assert_equal('test 3', ticket3.title, 'ticket3.title verify')
    assert_equal('Users', ticket3.group.name, 'ticket3.group verify')
    assert_equal('new', ticket3.state.name, 'ticket3.state verify')
    assert_equal('2 normal', ticket3.priority.name, 'ticket3.priority verify')
    assert_equal(1, ticket3.articles.count, 'ticket3.articles verify')
    assert_equal([], ticket3.tag_list)
    Observer::Transaction.commit
    ticket3.reload
    assert_equal('test 3', ticket3.title, 'ticket3.title verify')
    assert_equal('Users', ticket3.group.name, 'ticket3.group verify')
    assert_equal('new', ticket3.state.name, 'ticket3.state verify')
    assert_equal('2 normal', ticket3.priority.name, 'ticket3.priority verify')
    assert_equal(2, ticket3.articles.count, 'ticket3.articles verify')
    assert_equal([], ticket3.tag_list)
    article1 = ticket3.articles.last

  end

  test 'article.body' do
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
        },
        'article.body' => {
          'operator' => 'contains',
          'value' => 'hello',
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
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

    ticket1 = Ticket.create!(
      title: 'test 1',
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message <b>note</b> hello ',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1.reload
    assert_equal('test 1', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal([], ticket1.tag_list)

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('test 1', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal(%w[aa kk], ticket1.tag_list)
    article1 = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', article1.from)
    assert_match('nicole.braun@zammad.org', article1.to)
    assert_match('Thanks for your inquiry (test 1)!', article1.subject)
    assert_match('some message', article1.body)
    assert_match('&gt; some message &lt;b&gt;note&lt;/b&gt; hello', article1.body)
    assert_equal('text/html', article1.content_type)

    ticket2 = Ticket.create!(
      title: 'test 1',
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket2.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message <b>note</b>',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket2.reload
    assert_equal('test 1', ticket2.title, 'ticket2.title verify')
    assert_equal('Users', ticket2.group.name, 'ticket2.group verify')
    assert_equal('new', ticket2.state.name, 'ticket2.state verify')
    assert_equal('2 normal', ticket2.priority.name, 'ticket2.priority verify')
    assert_equal(1, ticket2.articles.count, 'ticket2.articles verify')
    assert_equal([], ticket2.tag_list)

    Observer::Transaction.commit

    ticket2.reload
    assert_equal('test 1', ticket2.title, 'ticket2.title verify')
    assert_equal('Users', ticket2.group.name, 'ticket2.group verify')
    assert_equal('new', ticket2.state.name, 'ticket2.state verify')
    assert_equal(1, ticket2.articles.count, 'ticket2.articles verify')
    assert_equal(%w[], ticket2.tag_list)

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
        },
        'article.body' => {
          'operator' => 'contains not',
          'value' => 'hello',
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
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

    ticket3 = Ticket.create!(
      title: 'test 1',
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket3.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message <b>note</b> hello ',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket3.reload
    assert_equal('test 1', ticket3.title, 'ticket3.title verify')
    assert_equal('Users', ticket3.group.name, 'ticket3.group verify')
    assert_equal('new', ticket3.state.name, 'ticket3.state verify')
    assert_equal('2 normal', ticket3.priority.name, 'ticket3.priority verify')
    assert_equal(1, ticket3.articles.count, 'ticket3.articles verify')
    assert_equal([], ticket3.tag_list)

    Observer::Transaction.commit

    ticket3.reload
    assert_equal('test 1', ticket3.title, 'ticket3.title verify')
    assert_equal('Users', ticket3.group.name, 'ticket3.group verify')
    assert_equal('new', ticket3.state.name, 'ticket3.state verify')
    assert_equal(1, ticket3.articles.count, 'ticket3.articles verify')
    assert_equal(%w[], ticket3.tag_list)

    ticket4 = Ticket.create!(
      title: 'test 1',
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: ticket4.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message <b>note</b> 2',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket4.reload
    assert_equal('test 1', ticket4.title, 'ticket4.title verify')
    assert_equal('Users', ticket4.group.name, 'ticket4.group verify')
    assert_equal('new', ticket4.state.name, 'ticket4.state verify')
    assert_equal('2 normal', ticket4.priority.name, 'ticket4.priority verify')
    assert_equal(1, ticket4.articles.count, 'ticket4.articles verify')
    assert_equal([], ticket4.tag_list)

    Observer::Transaction.commit

    ticket4.reload
    assert_equal('test 1', ticket4.title, 'ticket4.title verify')
    assert_equal('Users', ticket4.group.name, 'ticket4.group verify')
    assert_equal('new', ticket4.state.name, 'ticket4.state verify')
    assert_equal(2, ticket4.articles.count, 'ticket4.articles verify')
    assert_equal(%w[aa kk], ticket4.tag_list)
    article4 = ticket4.articles.last
    assert_match('Zammad <zammad@localhost>', article4.from)
    assert_match('nicole.braun@zammad.org', article4.to)
    assert_match('Thanks for your inquiry (test 1)!', article4.subject)
    assert_match('some message', article4.body)
    assert_match('&gt; some message &lt;b&gt;note&lt;/b&gt; 2', article4.body)
    assert_equal('text/html', article4.content_type)

  end

  test 'change owner' do
    roles = Role.where(name: 'Agent')
    groups = Group.where(name: 'Users')
    agent1 = User.create_or_update(
      login: 'agent-has-changed@example.com',
      firstname: 'Has Changed',
      lastname: 'Agent1',
      email: 'agent-has-changed@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )

    agent2 = User.create_or_update(
      login: 'agent-has-changed2@example.com',
      firstname: 'Has Changed',
      lastname: 'Agent2',
      email: 'agent-has-changed2@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )

    # multi tag trigger with changed owner
    trigger1 = Trigger.create_or_update(
      name: 'change owner',
      condition: {
        'ticket.owner_id' => {
          'operator' => 'has changed',
        },
        'ticket.tags' => {
          'operator' => 'contains one not',
          'value' => 'nosendmail test123'
        }
      },
      perform: {
        'ticket.tags' => {
          'operator' => 'add',
          'value' => '123'
        },
        'notification.email' => {
          'body' => 'some lala',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry - 1234 check (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    # single tag trigger with changed owner
    trigger2 = Trigger.create_or_update(
      name: 'change owner',
      condition: {
        'ticket.owner_id' => {
          'operator' => 'has changed',
        },
        'ticket.tags' => {
          'operator' => 'contains one not',
          'value' => 'nosendmail2',
        }
      },
      perform: {
        'ticket.tags' => {
          'operator' => 'add',
          'value' => '123'
        },
        'notification.email' => {
          'body' => 'some lala',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry - 1234 check (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: "some title\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(0, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal('agent-has-changed@example.com', agent1.login, 'verify agent')
    assert_equal([], ticket1.tag_list, 'ticket1.tag_list')

    ticket2 = Ticket.create!(
      title: "some title\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_equal('some title  äöüß', ticket2.title, 'ticket1.title verify')
    assert_equal('Users', ticket2.group.name, 'ticket2.group verify')
    assert_equal('new', ticket2.state.name, 'ticket2.state verify')
    assert_equal('2 normal', ticket2.priority.name, 'ticket2.priority verify')
    assert_equal(0, ticket2.articles.count, 'ticket2.articles verify')
    assert_equal('agent-has-changed@example.com', agent1.login, 'verify agent')
    assert_equal([], ticket1.tag_list, 'ticket2.tag_list')

    # control test - should pass
    # create common object tag
    tag_object = Tag::Object.create_or_update(name: 'Ticket')

    # add tag
    ticket1.tag_add('thisisthebestjob', agent1.id)

    # change owner
    ticket1.owner_id = agent1.id
    ticket1.save!

    Observer::Transaction.commit

    # this will add a tag by trigger
    ticket1.reload
    assert_equal('some title  äöüß', ticket1.title, 'ticket2.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket2.group verify')
    assert_equal('new', ticket1.state.name, 'ticket2.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket2.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket2.articles verify') # articles.count must be 1 if the tag is added
    assert_equal('agent-has-changed@example.com', agent1.login, 'verify agent')
    assert_equal(%w[thisisthebestjob 123], ticket1.tag_list, 'ticket2.tag_list')

    # add tag nosendmail (to test the bug)
    ticket1.tag_add('nosendmail', agent2.id)

    # change owner
    ticket1.owner_id = agent2.id
    ticket1.save!

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify') # articles.count must be 0 if adding tag is skipped
    assert_equal('agent-has-changed2@example.com', agent2.login, 'verify agent')
    assert_equal(%w[thisisthebestjob 123 nosendmail], ticket1.tag_list, 'ticket1.tag_list')

    # add tag (to test the bug)
    ticket1.tag_add('test123', agent2.id)

    # change owner
    ticket1.owner_id = agent1.id
    ticket1.save!

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('some title  äöüß', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(3, ticket1.articles.count, 'ticket1.articles verify') # articles.count must be 0 if adding tag is skipped
    assert_equal('agent-has-changed@example.com', agent1.login, 'verify agent')
    assert_equal(%w[thisisthebestjob 123 nosendmail test123], ticket1.tag_list, 'ticket1.tag_list')

    # add tag single tag 'nosendmail2' (to test the bug)
    ticket2.tag_add('nosendmail2', agent1.id)

    # change owner
    ticket2.owner_id = agent1.id
    ticket2.save!

    Observer::Transaction.commit

    ticket2.reload
    assert_equal('some title  äöüß', ticket2.title, 'ticket2.title verify')
    assert_equal('Users', ticket2.group.name, 'ticket2.group verify')
    assert_equal('new', ticket2.state.name, 'ticket2.state verify')
    assert_equal('2 normal', ticket2.priority.name, 'ticket2.priority verify')
    assert_equal(0, ticket2.articles.count, 'ticket2.articles verify') # articles.count must be 0 if adding tag is skipped
    assert_equal('agent-has-changed@example.com', agent1.login, 'verify agent')
    assert_equal(['nosendmail2'], ticket2.tag_list, 'ticket2.tag_list')

  end

  test 'trigger auto reply with umlaut in form' do
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
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'article_last_sender',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ticket1 = Ticket.create!(
      title: 'test 1',
      group: Group.lookup(name: 'Users'),
      customer: User.lookup(email: 'nicole.braun@zammad.org'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'Sabine Schütz <some_sender@example.com>',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message <b>note</b> hello ',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1.reload
    assert_equal('test 1', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal('2 normal', ticket1.priority.name, 'ticket1.priority verify')
    assert_equal(1, ticket1.articles.count, 'ticket1.articles verify')
    assert_equal('Sabine Schütz <some_sender@example.com>', ticket1.articles.first.from, 'ticket1.articles.first.from verify')
    assert_equal([], ticket1.tag_list)

    Observer::Transaction.commit

    ticket1.reload
    assert_equal('test 1', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    article1 = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', article1.from)
    assert_match('some_sender@example.com', article1.to)
    assert_match('Thanks for your inquiry (test 1)!', article1.subject)
    assert_match('some message', article1.body)
    assert_match('&gt; some message &lt;b&gt;note&lt;/b&gt; hello', article1.body)
    assert_equal('text/html', article1.content_type)

  end

  test 'trigger auto reply with 2 sender addresses in form' do
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
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'article_last_sender',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ticket1, article1, user, mail = Channel::EmailParser.new.process({}, File.read(Rails.root.join('test', 'data', 'mail', 'mail065.box')))

    assert_equal('aaäöüßad asd', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    article1 = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', article1.from)
    assert_match('smith@example.com', article1.to)
    assert_match('Thanks for your inquiry (aaäöüßad asd)!', article1.subject)
    assert_match('some text<br><br>aaäöüßad asd', article1.body)
    assert_equal('text/html', article1.content_type)

  end

  test 'make sure attachments should be attached with content id' do
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
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}<br><img tabindex="0" style="width: 192px; height: 192px" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCADAAMADAREAAhEBAxEB/8QAHgABAAICAwEBAQAAAAAAAAAAAAcICQoFBgsDAQT/xAA7EAAABwEAAQMCAgYJAgcAAAAAAQIDBAUGBwgJERITIQoUFRciMXa1FiMyNzg5QVF3JLIYGSc1QkVh/8QAHQEBAAICAwEBAAAAAAAAAAAAAAQFAwYCBwgBCf/EAEURAAICAgEDAgMEBAkLBAMAAAECAAMEEQUGEiETMQciQQgUMlEjYXF2FTM1QnJzgZGzFjY3OFJiobGytLUXGILBJTRD/9oADAMBAAIRAxEAPwDU/G4SPARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARLM+HPi5uvNDyU5T4086cbiaXp+iTU/piTGflwM3TxYsiyv9PZx4xk+5WZ+nhzLSelk/qnGjLJslLNKT++Atjk6Wquy1z/uo">',
          'recipient' => 'article_last_sender',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ticket1, article1, user, mail = Channel::EmailParser.new.process({}, File.read(Rails.root.join('test', 'data', 'mail', 'mail065.box')))

    assert_equal('aaäöüßad asd', ticket1.title, 'ticket1.title verify')
    assert_equal('Users', ticket1.group.name, 'ticket1.group verify')
    assert_equal('new', ticket1.state.name, 'ticket1.state verify')
    assert_equal(2, ticket1.articles.count, 'ticket1.articles verify')
    article1 = ticket1.articles.last
    assert_match('Zammad <zammad@localhost>', article1.from)
    assert_match('smith@example.com', article1.to)
    assert_match('Thanks for your inquiry (aaäöüßad asd)!', article1.subject)
    assert_match(/.+cid:.+?@zammad.example.com.+/, article1.body)
    assert_equal(1, article1.attachments.count)
    assert_equal('789', article1.attachments[0].size)
    assert_equal('text/html', article1.content_type)
  end

  # Issue #1316 - 'organization is not X' conditions break triggers
  test 'NOT IN predicates handle NULL values' do
    customer = User.create!(
      email: 'issue_1316_test_user@zammad.org',
      created_by_id: 1,
      updated_by_id: 1,
    )

    Trigger.create_or_update(
      name: 'auto reply (condition: organization-is-not)',
      condition: {
        'ticket.organization_id' => {
          'operator' => 'is not',
          'value' => Organization.first.id.to_s,
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'Lorem ipsum dolor',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
      },
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ticket = Ticket.create!(
      title: "some <b>title</b>\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer: customer,
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_nil(customer.organization_id)
    assert_equal(0, ticket.reload.articles.count, 'ticket.articles verify')

    Observer::Transaction.commit

    assert_equal(1, ticket.reload.articles.count, 'ticket.articles verify')

    autoreply = ticket.articles.first
    assert_equal('Zammad <zammad@localhost>', autoreply.from)
    assert_equal(customer.email, autoreply.to)
    assert_equal("Thanks for your inquiry (#{ticket.title})!", autoreply.subject)
    assert_equal('Lorem ipsum dolor', autoreply.body)
    assert_equal('text/html', autoreply.content_type)
  end
end
