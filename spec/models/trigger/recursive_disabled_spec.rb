# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Trigger, type: :model do
  describe 'when recursive trigger execution is disabled' do
    before do
      described_class.destroy_all # Default DB state includes three sample triggers
      create(:email_address, name: 'Zammad', email: 'zammad@localhost') # gets auto-assigned to the sole existing group
      Setting.set('ticket_trigger_recursive', false)
    end

    it 'runs a full ticket/article lifecycle through multiple non-recursive triggers (tags, priority, and email notification) without loops', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'aaa loop check',
        condition:            {
          'article.subject' => {
            'operator' => 'contains',
            'value'    => 'Thanks for your inquiry',
          },
        },
        perform:              {
          'ticket.tags'        => {
            'operator' => 'add',
            'value'    => 'should_not_loop',
          },
          'notification.email' => {
            'body'      => 'some lala',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry - loop check (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
          'ticket.priority_id' => {
            'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
          },
          'ticket.tags'        => {
            'operator' => 'add',
            'value'    => 'aa, kk',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      described_class.create_or_update(
        name:                 'auto tag 1',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'update',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
          'ticket.priority_id' => {
            'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
          },
          'ticket.tags'        => {
            'operator' => 'remove',
            'value'    => 'kk',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      described_class.create_or_update(
        name:                 'auto tag 2',
        condition:            {
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
          'ticket.tags' => {
            'operator' => 'add',
            'value'    => 'abc',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      described_class.create_or_update(
        name:                 'not matching',
        condition:            {
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'closed').id.to_s,
          }
        },
        perform:              {
          'ticket.priority_id' => {
            'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      described_class.create_or_update(
        name:                 'zzz last',
        condition:            {
          'article.subject' => {
            'operator' => 'contains',
            'value'    => 'some subject 1234',
          },
        },
        perform:              {
          'ticket.tags'        => {
            'operator' => 'add',
            'value'    => 'article_create_trigger',
          },
          'notification.email' => {
            'body'      => 'some lala',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry - 1234 check (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      ticket1 = Ticket.create!(
        title:         "some <b>title</b>\n äöüß",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1.reload
      expect(ticket1.title).to eq('some <b>title</b>  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq([])

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('some <b>title</b>  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('3 high')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq(%w[aa kk abc])
      article1 = ticket1.articles.last
      expect(article1.from).to include('Zammad <zammad@localhost>')
      expect(article1.to).to include('nicole.braun@zammad.org')
      expect(article1.subject).to include('Thanks for your inquiry (some <b>title</b>  äöüß)!')
      expect(article1.body).to include('Braun<br>some &lt;b&gt;title&lt;/b&gt;')
      expect(article1.body).to include('&gt; some message &lt;b&gt;note&lt;/b&gt;<br>&gt; new line')
      expect(article1.content_type).to eq('text/html')

      ticket1.priority = Ticket::Priority.lookup(name: '2 normal')
      ticket1.save!
      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('some <b>title</b>  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq(%w[aa kk abc])

      ticket1.state = Ticket::State.lookup(name: 'open')
      ticket1.save!

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('some <b>title</b>  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('open')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq(%w[aa kk abc])

      ticket1.state = Ticket::State.lookup(name: 'new')
      ticket1.save!

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('some <b>title</b>  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('3 high')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq(%w[aa abc])

      ticket2 = Ticket.create!(
        title:         "some title\n äöüß",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        state:         Ticket::State.lookup(name: 'open'),
        priority:      Ticket::Priority.lookup(name: '2 normal'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      expect(ticket2.title).to eq('some title  äöüß')
      expect(ticket2.group.name).to eq('Users')
      expect(ticket2.state.name).to eq('open')
      expect(ticket2.priority.name).to eq('2 normal')
      expect(ticket2.articles.count).to eq(0)
      expect(ticket2.tag_list).to eq([])

      TransactionDispatcher.commit

      ticket2.reload
      expect(ticket2.title).to eq('some title  äöüß')
      expect(ticket2.group.name).to eq('Users')
      expect(ticket2.state.name).to eq('open')
      expect(ticket2.priority.name).to eq('2 normal')
      expect(ticket2.articles.count).to eq(0)
      expect(ticket2.tag_list).to eq([])

      ticket3 = Ticket.create!(
        title:         "some <b>title</b>\n äöüß3",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      expect(ticket3).to be_truthy

      Ticket::Article.create!(
        ticket_id:     ticket3.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      expect(ticket3.title).to eq('some <b>title</b>  äöüß3')
      expect(ticket3.group.name).to eq('Users')
      expect(ticket3.state.name).to eq('new')
      expect(ticket3.priority.name).to eq('2 normal')
      expect(ticket3.articles.count).to eq(1)
      expect(ticket3.tag_list).to eq([])

      TransactionDispatcher.commit

      ticket3.reload
      expect(ticket3.title).to eq('some <b>title</b>  äöüß3')
      expect(ticket3.group.name).to eq('Users')
      expect(ticket3.state.name).to eq('new')
      expect(ticket3.priority.name).to eq('3 high')
      expect(ticket3.articles.count).to eq(3)
      expect(ticket3.tag_list).to eq(%w[aa kk abc article_create_trigger])
      article3 = ticket3.articles[1]
      expect(article3.from).to include('Zammad <zammad@localhost>')
      expect(article3.to).to include('nicole.braun@zammad.org')
      expect(article3.subject).to include('Thanks for your inquiry (some <b>title</b>  äöüß3)!')
      expect(article3.body).to include('Braun<br>some &lt;b&gt;title&lt;/b&gt;')
      expect(article3.body).to include('&gt; some message note<br>&gt; new line')
      expect(article3.body).not_to include('&gt; some message &lt;b&gt;note&lt;/b&gt;<br>&gt; new line')
      expect(article3.content_type).to eq('text/html')
      article3 = ticket3.articles[2]
      expect(article3.from).to include('Zammad <zammad@localhost>')
      expect(article3.to).to include('nicole.braun@zammad.org')
      expect(article3.subject).to include('Thanks for your inquiry - 1234 check (some <b>title</b>  äöüß3)!')
      expect(article3.content_type).to eq('text/html')

      Ticket::Article.create!(
        ticket_id:     ticket3.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject - not 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit

      ticket3.reload
      expect(ticket3.title).to eq('some <b>title</b>  äöüß3')
      expect(ticket3.group.name).to eq('Users')
      expect(ticket3.state.name).to eq('new')
      expect(ticket3.priority.name).to eq('3 high')
      expect(ticket3.articles.count).to eq(4)
      expect(ticket3.tag_list).to eq(%w[aa abc article_create_trigger])

      Ticket::Article.create!(
        ticket_id:     ticket3.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject NOT 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit

      ticket3.reload
      expect(ticket3.title).to eq('some <b>title</b>  äöüß3')
      expect(ticket3.group.name).to eq('Users')
      expect(ticket3.state.name).to eq('new')
      expect(ticket3.priority.name).to eq('3 high')
      expect(ticket3.articles.count).to eq(5)
      expect(ticket3.tag_list).to eq(%w[aa abc article_create_trigger])

      Ticket::Article.create!(
        ticket_id:     ticket3.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit

      ticket3.reload
      expect(ticket3.title).to eq('some <b>title</b>  äöüß3')
      expect(ticket3.group.name).to eq('Users')
      expect(ticket3.state.name).to eq('new')
      expect(ticket3.priority.name).to eq('3 high')
      expect(ticket3.articles.count).to eq(7)
      expect(ticket3.tag_list).to eq(%w[aa abc article_create_trigger])
    end

    it 'only executes a trigger scoped to the create action when a ticket is created, not on later updates', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
          'notification.email' => {
            'body'      => 'dasdasdasd',
            'recipient' => 'ticket_customer',
            'subject'   => 'asdasdas',
          },
          'ticket.priority_id' => {
            'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      ticket1 = Ticket.create!(
        title:         "some title\n äöüß",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(0)

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('3 high')
      expect(ticket1.articles.count).to eq(1)
      article1 = ticket1.articles.last
      expect(article1.from).to include('Zammad <zammad@localhost>')
      expect(article1.to).to include('nicole.braun@zammad.org')
      expect(article1.subject).to include('asdasdas')
      expect(article1.body).to include('dasdasdasd')
      expect(article1.content_type).to eq('text/html')

      ticket1.priority = Ticket::Priority.lookup(name: '2 normal')
      ticket1.save!

      TransactionDispatcher.commit

      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)

      ticket1.state = Ticket::State.lookup(name: 'open')
      ticket1.save!

      TransactionDispatcher.commit

      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('open')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)

      ticket1.state = Ticket::State.lookup(name: 'new')
      ticket1.save!

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
    end

    it 'only executes a trigger scoped to the update action when a ticket is updated, not on creation', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'update',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
          'notification.email' => {
            'body'      => 'dasdasdasd',
            'recipient' => 'ticket_customer',
            'subject'   => 'asdasdas',
          },
          'ticket.priority_id' => {
            'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      ticket1 = Ticket.create!(
        title:         "some title\n äöüß",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(0)

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(0)

      ticket1.priority = Ticket::Priority.lookup(name: '2 normal')
      ticket1.save!

      TransactionDispatcher.commit

      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(0)

      ticket1.state = Ticket::State.lookup(name: 'open')
      ticket1.save!

      TransactionDispatcher.commit

      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('open')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(0)

      ticket1.state = Ticket::State.lookup(name: 'new')
      ticket1.save!

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('3 high')
      expect(ticket1.articles.count).to eq(1)
    end

    it 'sends auto-reply notifications for new tickets and customer follow-ups while respecting Precedence and abuse headers', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      roles = Role.where(name: 'Customer')
      User.create_or_update(
        login:         'postmaster@example.com',
        firstname:     'Trigger',
        lastname:      'Customer1',
        email:         'postmaster@example.com',
        password:      'customerpw',
        active:        true,
        roles:         roles,
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
      User.create_or_update(
        login:           'ticket-auto-reply-customer2@example.com',
        firstname:       'Trigger',
        lastname:        'Customer2',
        email:           'ticket-auto-reply-customer2@example.com',
        password:        'customerpw',
        active:          true,
        organization_id: nil,
        roles:           roles,
        updated_at:      '2015-02-05 16:37:00',
        updated_by_id:   1,
        created_by_id:   1,
      )

      described_class.create_or_update(
        name:                 'auto reply - new ticket',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is not',
            'value'    => Ticket::State.lookup(name: 'closed').id,
          },
          'article.type_id' => {
            'operator' => 'is',
            'value'    => [
              Ticket::Article::Type.lookup(name: 'email').id,
              Ticket::Article::Type.lookup(name: 'phone').id,
              Ticket::Article::Type.lookup(name: 'web').id,
            ],
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => '<p>Your request (Ticket##{ticket.number}) has been received and will be reviewed by our support staff.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      described_class.create_or_update(
        name:          'auto reply (on follow-up of tickets)',
        condition:     {
          'ticket.action'     => {
            'operator' => 'is',
            'value'    => 'update',
          },
          'article.sender_id' => {
            'operator' => 'is',
            'value'    => Ticket::Article::Sender.lookup(name: 'Customer').id,
          },
          'article.type_id'   => {
            'operator' => 'is',
            'value'    => [
              Ticket::Article::Type.lookup(name: 'email').id,
              Ticket::Article::Type.lookup(name: 'phone').id,
              Ticket::Article::Type.lookup(name: 'web').id,
            ],
          },
        },
        perform:       {
          'notification.email' => {
            'body'      => '<p>Your follow-up for (#{config.ticket_hook}##{ticket.number}) has been received and will be reviewed by our support staff.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your follow-up (#{ticket.title})',
          },
        },
        active:        true,
        created_by_id: 1,
        updated_by_id: 1,
      )

      described_class.create_or_update(
        name:                 'not matching',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'closed').id.to_s,
          }
        },
        perform:              {
          'notification.email' => {
            'body'      => '2some text<br>#{ticket.customer.lastname}<br>#{ticket.title}',
            'recipient' => 'ticket_customer',
            'subject'   => '2Thanks for your inquiry (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      # process mail without Precedence header
      content = Rails.root.join('test/data/ticket_trigger/mail1.box').read
      ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, content)

      expect(ticket_p.title).to eq('aaäöüßad asd')
      expect(ticket_p.group.name).to eq('Users')
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.articles.count).to eq(2)
      article_p = ticket_p.articles.last
      expect(article_p.subject).to include('Thanks for your inquiry (aaäöüßad asd)')
      expect(article_p.from).to include('Zammad <zammad@localhost>')
      expect(article_p.body).not_to include('config\.')
      expect(article_p.body).to include('http://zammad.example.com')
      expect(article_p.body).not_to include('ticket.')
      expect(article_p.body).to match(ticket_p.number)
      expect(article_p.content_type).to eq('text/html')

      ticket_p.priority = Ticket::Priority.lookup(name: '2 normal')
      ticket_p.save!
      TransactionDispatcher.commit
      expect(ticket_p.title).to eq('aaäöüßad asd')
      expect(ticket_p.group.name).to eq('Users')
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('2 normal')
      expect(ticket_p.articles.count).to eq(2)

      Ticket::Article.create!(
        ticket_id:     ticket_p.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          'some message note',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit
      expect(ticket_p.title).to eq('aaäöüßad asd')
      expect(ticket_p.group.name).to eq('Users')
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('2 normal')
      expect(ticket_p.articles.count).to eq(3)

      Ticket::Article.create!(
        ticket_id:     ticket_p.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          'some message note',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit
      expect(ticket_p.title).to eq('aaäöüßad asd')
      expect(ticket_p.group.name).to eq('Users')
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('2 normal')
      expect(ticket_p.articles.count).to eq(4)

      Ticket::Article.create!(
        ticket_id:     ticket_p.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          'some message note',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit
      expect(ticket_p.title).to eq('aaäöüßad asd')
      expect(ticket_p.group.name).to eq('Users')
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('2 normal')
      expect(ticket_p.articles.count).to eq(6)

      article_p = ticket_p.articles.last
      expect(article_p.subject).to include('Thanks for your follow-up (aaäöüßad asd)')
      expect(article_p.from).to include('Zammad <zammad@localhost>')
      expect(article_p.body).not_to include('config\.')
      expect(article_p.body).to include('http://zammad.example.com')
      expect(article_p.body).not_to include('ticket.')
      expect(article_p.body).to match(ticket_p.number)
      expect(article_p.content_type).to eq('text/html')

      ticket_p.state = Ticket::State.lookup(name: 'open')
      ticket_p.save!
      Ticket::Article.create!(
        ticket_id:     ticket_p.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          'some message note',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit
      expect(ticket_p.title).to eq('aaäöüßad asd')
      expect(ticket_p.group.name).to eq('Users')
      expect(ticket_p.state.name).to eq('open')
      expect(ticket_p.priority.name).to eq('2 normal')
      expect(ticket_p.articles.count).to eq(8)

      article_p = ticket_p.articles.last
      expect(article_p.subject).to include('Thanks for your follow-up (aaäöüßad asd)')
      expect(article_p.from).to include('Zammad <zammad@localhost>')
      expect(article_p.body).not_to include('config\.')
      expect(article_p.body).to include('http://zammad.example.com')
      expect(article_p.body).not_to include('ticket.')
      expect(article_p.body).to match(ticket_p.number)
      expect(article_p.content_type).to eq('text/html')

      # process mail without Precedence header
      content = Rails.root.join('test/data/ticket_trigger/mail1.box').read
      ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, content)

      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.articles.count).to eq(2)

      # process mail with Precedence header (no auto response)
      content = Rails.root.join('test/data/ticket_trigger/mail2.box').read
      ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, content)

      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.articles.count).to eq(1)

      # process mail with abuse@ (no auto response)
      content = Rails.root.join('test/data/ticket_trigger/mail3.box').read
      ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, content)

      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.articles.count).to eq(1)
    end

    it 'fires an owner-changed trigger based on a \'has changed\' pre-condition combined with additional matching conditions', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      roles = Role.where(name: 'Customer')
      User.create_or_update(
        login:         'postmaster@example.com',
        firstname:     'Trigger',
        lastname:      'Customer1',
        email:         'postmaster@example.com',
        password:      'customerpw',
        active:        true,
        roles:         roles,
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
      User.create_or_update(
        login:           'ticket-has-changed-customer2@example.com',
        firstname:       'Trigger',
        lastname:        'Customer2',
        email:           'ticket-has-changed-customer2@example.com',
        password:        'customerpw',
        active:          true,
        organization_id: nil,
        roles:           roles,
        updated_at:      '2015-02-05 16:37:00',
        updated_by_id:   1,
        created_by_id:   1,
      )
      groups = Group.where(name: 'Users')
      roles = Role.where(name: 'Agent')
      agent1 = User.create_or_update(
        login:         'agent-has-changed@example.com',
        firstname:     'Has Changed',
        lastname:      'Agent1',
        email:         'agent-has-changed@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
      described_class.create_or_update(
        name:                 'owner update - to customer',
        condition:            {
          'ticket.owner_id' => {
            'operator'         => 'has changed',
            'pre_condition'    => 'current_user.id',
            'value'            => '',
            'value_completion' => '',
          }
        },
        perform:              {
          'notification.email' => {
            'body'      => '<p>The owner of ticket (Ticket##{ticket.number}) has changed.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
            'recipient' => 'ticket_customer',
            'subject'   => 'Owner has changed (#{ticket.title})',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      # process mail without Precedence header
      content = Rails.root.join('test/data/ticket_trigger/mail1.box').read
      ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, content)

      expect(ticket_p.title).to eq('aaäöüßad asd')
      expect(ticket_p.group.name).to eq('Users')
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.articles.count).to eq(1)

      TransactionDispatcher.commit

      ticket_p.owner = agent1
      ticket_p.save!
      TransactionDispatcher.commit
      expect(ticket_p.title).to eq('aaäöüßad asd')
      expect(ticket_p.group.name).to eq('Users')
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('2 normal')
      expect(ticket_p.articles.count).to eq(2)

      # p ticket_p.articles.last.inspect
      article_p = ticket_p.articles.last
      expect(article_p.subject).to include('Owner has changed')
      expect(article_p.from).to include('Zammad <zammad@localhost>')
      expect(article_p.to).to include('martin@example.com')
      expect(article_p.body).not_to include('config\.')
      expect(article_p.body).to include('http://zammad.example.com')
      expect(article_p.body).not_to include('ticket.')
      expect(article_p.body).to match(ticket_p.number)
      expect(article_p.content_type).to eq('text/html')

      described_class.create_or_update(
        name:                 'owner update - to customer',
        condition:            {
          'ticket.owner_id'    => {
            'operator'         => 'has changed',
            'pre_condition'    => 'current_user.id',
            'value'            => '',
            'value_completion' => '',
          },
          'ticket.priority_id' => {
            'operator' => 'is',
            'value'    => Ticket::Priority.lookup(name: '3 high').id.to_s,
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => '<p>The owner of ticket (Ticket##{ticket.number}) has changed.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
            'recipient' => 'ticket_customer',
            'subject'   => 'Owner has changed (#{ticket.title})',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      # process mail without Precedence header
      content = Rails.root.join('test/data/ticket_trigger/mail1.box').read
      ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, content)

      expect(ticket_p.title).to eq('aaäöüßad asd')
      expect(ticket_p.group.name).to eq('Users')
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.articles.count).to eq(1)

      TransactionDispatcher.commit
      expect(ticket_p.articles.count).to eq(1)

      ticket_p.priority = Ticket::Priority.lookup(name: '1 low')
      ticket_p.save!

      TransactionDispatcher.commit
      expect(ticket_p.articles.count).to eq(1)

      ticket_p.priority = Ticket::Priority.lookup(name: '3 high')
      ticket_p.save!

      TransactionDispatcher.commit
      expect(ticket_p.articles.count).to eq(1)

      ticket_p.owner = agent1
      ticket_p.save!

      TransactionDispatcher.commit

      expect(ticket_p.title).to eq('aaäöüßad asd')
      expect(ticket_p.group.name).to eq('Users')
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(ticket_p.articles.count).to eq(2)

      # p ticket_p.articles.last.inspect
      article_p = ticket_p.articles.last
      expect(article_p.subject).to include('Owner has changed')
      expect(article_p.from).to include('Zammad <zammad@localhost>')
      expect(article_p.to).to include('martin@example.com')
      expect(article_p.body).not_to include('config\.')
      expect(article_p.body).to include('http://zammad.example.com')
      expect(article_p.body).not_to include('ticket.')
      expect(article_p.body).to match(ticket_p.number)
      expect(article_p.content_type).to eq('text/html')

      # should trigger
      described_class.create_or_update(
        name:                 'owner update - to customer',
        condition:            {
          'ticket.owner_id'    => {
            'operator'         => 'has changed',
            'pre_condition'    => 'current_user.id',
            'value'            => '',
            'value_completion' => '',
          },
          'ticket.priority_id' => {
            'operator' => 'is',
            'value'    => Ticket::Priority.lookup(name: '3 high').id.to_s,
          },
          'ticket.action'      => {
            'operator' => 'is not',
            'value'    => 'create',
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => '<p>The owner of ticket (Ticket##{ticket.number}) has changed.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
            'recipient' => 'ticket_customer',
            'subject'   => 'Owner has changed (#{ticket.title})',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      # process mail without Precedence header
      content = Rails.root.join('test/data/ticket_trigger/mail1.box').read
      ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, content)

      expect(ticket_p.title).to eq('aaäöüßad asd')
      expect(ticket_p.group.name).to eq('Users')
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.articles.count).to eq(1)

      TransactionDispatcher.commit
      expect(ticket_p.articles.count).to eq(1)

      ticket_p.priority = Ticket::Priority.lookup(name: '1 low')
      ticket_p.save!

      TransactionDispatcher.commit
      expect(ticket_p.articles.count).to eq(1)

      ticket_p.priority = Ticket::Priority.lookup(name: '3 high')
      ticket_p.save!

      TransactionDispatcher.commit
      expect(ticket_p.articles.count).to eq(1)

      ticket_p.owner = agent1
      ticket_p.save!

      TransactionDispatcher.commit
      expect(ticket_p.title).to eq('aaäöüßad asd')
      expect(ticket_p.group.name).to eq('Users')
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(ticket_p.articles.count).to eq(2)

      # p ticket_p.articles.last.inspect
      article_p = ticket_p.articles.last
      expect(article_p.subject).to include('Owner has changed')
      expect(article_p.from).to include('Zammad <zammad@localhost>')
      expect(article_p.to).to include('martin@example.com')
      expect(article_p.body).not_to include('config\.')
      expect(article_p.body).to include('http://zammad.example.com')
      expect(article_p.body).not_to include('ticket.')
      expect(article_p.body).to match(ticket_p.number)
      expect(article_p.content_type).to eq('text/html')

      # should not trigger
      described_class.create_or_update(
        name:                 'owner update - to customer',
        condition:            {
          'ticket.owner_id' => {
            'operator'         => 'has changed',
            'pre_condition'    => 'current_user.id',
            'value'            => '',
            'value_completion' => '',
          },
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => '<p>The owner of ticket (Ticket##{ticket.number}) has changed.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
            'recipient' => 'ticket_customer',
            'subject'   => 'Owner has changed (#{ticket.title})',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      # process mail without Precedence header
      content = Rails.root.join('test/data/ticket_trigger/mail1.box').read
      ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, content)

      expect(ticket_p.articles.count).to eq(1)

      TransactionDispatcher.commit
      expect(ticket_p.articles.count).to eq(1)

      ticket_p.owner = agent1
      ticket_p.save!

      TransactionDispatcher.commit
      expect(ticket_p.articles.count).to eq(1)
    end

    it 'notifies the ticket owner on eligible updates without triggering itself recursively', :aggregate_failures do
      described_class.create_or_update(
        name:                 'aaa notify mail',
        condition:            {
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.pluck(:id),
          },
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'update',
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some lala',
            'recipient' => 'ticket_owner',
            'subject'   => 'CC NOTE (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      groups = Group.where(name: 'Users')
      roles = Role.where(name: 'Agent')
      agent = User.create_or_update(
        login:         'agent@example.com',
        firstname:     'Trigger',
        lastname:      'Agent1',
        email:         'agent@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1 = Ticket.create!(
        title:         'test 123',
        owner:         agent,
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq([])

      TransactionDispatcher.commit

      expect(ticket1.articles.count).to eq(1)

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'update',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'update',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit

      expect(ticket1.articles.count).to eq(3)

      described_class.create_or_update(
        name:                 'aaa notify mail 2',
        condition:            {
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.pluck(:id),
          },
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'update',
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some lala',
            'recipient' => 'ticket_owner',
            'subject'   => 'CC NOTE (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'update',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'update',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit

      expect(ticket1.articles.count).to eq(6)
    end

    it 'automatically assigns the ticket owner to the current user on update, based on a not-set pre-condition', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'aaa auto assignment',
        condition:            {
          'ticket.owner_id' => {
            'operator'         => 'is',
            'pre_condition'    => 'not_set',
            'value'            => '',
            'value_completion' => '',
          },
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'update',
          },
        },
        perform:              {
          'ticket.owner_id' => {
            'pre_condition'    => 'current_user.id',
            'value'            => '',
            'value_completion' => '',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      groups = Group.where(name: 'Users')
      roles = Role.where(name: 'Agent')
      agent = User.create_or_update(
        login:         'agent@example.com',
        firstname:     'Trigger',
        lastname:      'Agent1',
        email:         'agent@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1 = Ticket.create!(
        title:         'test 123',
        # owner: agent,
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit

      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(1)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent.id
      Ticket::Article.create!(
        ticket_id:    ticket1.id,
        from:         'some_sender@example.com',
        to:           'some_recipient@example.com',
        subject:      'update',
        message_id:   'some@id',
        content_type: 'text/html',
        body:         'update',
        internal:     false,
        sender:       Ticket::Article::Sender.find_by(name: 'Agent'),
        type:         Ticket::Article::Type.find_by(name: 'note'),
      )
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent.id
      ticket1.owner_id = 1
      ticket1.save!
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(1)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])

    end

    it 'automatically assigns the owner to the current user based on the ticket having an organization set', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'aaa auto assignment',
        condition:            {
          'ticket.organization_id' => {
            'operator'         => 'is not',
            'pre_condition'    => 'not_set',
            'value'            => '',
            'value_completion' => '',
          },
          'ticket.action'          => {
            'operator' => 'is',
            'value'    => 'update',
          },
        },
        perform:              {
          'ticket.owner_id' => {
            'pre_condition'    => 'current_user.id',
            'value'            => '',
            'value_completion' => '',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      roles = Role.where(name: 'Agent')
      groups = Group.where(name: 'Users')
      agent = User.create_or_update(
        login:         'agent@example.com',
        firstname:     'Trigger',
        lastname:      'Agent1',
        email:         'agent@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )
      roles = Role.where(name: 'Customer')
      customer = User.create_or_update(
        login:         'customer@example.com',
        firstname:     'Trigger',
        lastname:      'Customer1',
        email:         'customer@example.com',
        password:      'customerpw',
        vip:           true,
        active:        true,
        roles:         roles,
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1 = Ticket.create!(
        title:         'test 123',
        group:         Group.lookup(name: 'Users'),
        customer:      customer,
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit

      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(1)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq([])

      ticket1.update!(customer: User.lookup(email: 'nicole.braun@zammad.org'))

      UserInfo.current_user_id = agent.id
      Ticket::Article.create!(
        ticket_id:    ticket1.id,
        from:         'some_sender@example.com',
        to:           'some_recipient@example.com',
        subject:      'update',
        message_id:   'some@id',
        content_type: 'text/html',
        body:         'update',
        internal:     false,
        sender:       Ticket::Article::Sender.find_by(name: 'Agent'),
        type:         Ticket::Article::Type.find_by(name: 'note'),
      )
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])
    end

    it 'automatically assigns the owner to the current user based on the ticket having no organization set', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'aaa auto assignment',
        condition:            {
          'ticket.organization_id' => {
            'operator'         => 'is',
            'pre_condition'    => 'not_set',
            'value'            => '',
            'value_completion' => '',
          },
          'ticket.action'          => {
            'operator' => 'is',
            'value'    => 'update',
          },
        },
        perform:              {
          'ticket.owner_id' => {
            'pre_condition'    => 'current_user.id',
            'value'            => '',
            'value_completion' => '',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      groups = Group.where(name: 'Users')
      roles = Role.where(name: 'Agent')
      agent = User.create_or_update(
        login:         'agent@example.com',
        firstname:     'Trigger',
        lastname:      'Agent1',
        email:         'agent@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )
      roles = Role.where(name: 'Customer')
      customer = User.create_or_update(
        login:         'customer@example.com',
        firstname:     'Trigger',
        lastname:      'Customer1',
        email:         'customer@example.com',
        password:      'customerpw',
        vip:           true,
        active:        true,
        roles:         roles,
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1 = Ticket.create!(
        title:         'test 123',
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit

      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(1)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq([])

      ticket1.update!(customer: customer)

      UserInfo.current_user_id = agent.id
      Ticket::Article.create!(
        ticket_id:    ticket1.id,
        from:         'some_sender@example.com',
        to:           'some_recipient@example.com',
        subject:      'update',
        message_id:   'some@id',
        content_type: 'text/html',
        body:         'update',
        internal:     false,
        sender:       Ticket::Article::Sender.find_by(name: 'Agent'),
        type:         Ticket::Article::Type.find_by(name: 'note'),
      )
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])
    end

    it 'automatically assigns the owner based on article sender/type conditions and re-assigns correctly when the owner changes again', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'aaa auto assignment',
        condition:            {
          'ticket.owner_id'   => {
            'operator'         => 'is',
            'pre_condition'    => 'not_set',
            'value'            => '',
            'value_completion' => '',
          },
          'article.type_id'   => {
            'operator' => 'is',
            'value'    => Ticket::Article::Type.find_by(name: 'note'),
          },
          'article.sender_id' => {
            'operator' => 'is',
            'value'    => Ticket::Article::Sender.find_by(name: 'Agent'),
          },
        },
        perform:              {
          'ticket.owner_id' => {
            'pre_condition'    => 'current_user.id',
            'value'            => '',
            'value_completion' => '',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      groups = Group.where(name: 'Users')
      roles = Role.where(name: 'Agent')
      agent1 = User.create_or_update(
        login:         'agent@example.com',
        firstname:     'Trigger',
        lastname:      'Agent1',
        email:         'agent@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )
      agent2 = User.create_or_update(
        login:         'agent@example.com',
        firstname:     'Trigger',
        lastname:      'Agent2',
        email:         'agent@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1 = Ticket.create!(
        title:         'test 123',
        # owner: agent,
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit

      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(1)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent1.id
      Ticket::Article.create!(
        ticket_id:    ticket1.id,
        from:         'some_sender@example.com',
        to:           'some_recipient@example.com',
        subject:      'update',
        message_id:   'some@id',
        content_type: 'text/html',
        body:         'update',
        internal:     false,
        sender:       Ticket::Article::Sender.find_by(name: 'Agent'),
        type:         Ticket::Article::Type.find_by(name: 'note'),
      )
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent1.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent1.id
      ticket1.owner_id = 1
      ticket1.save!
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(1)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent1.id
      Ticket::Article.create!(
        ticket_id:    ticket1.id,
        from:         'some_sender@example.com',
        to:           'some_recipient@example.com',
        subject:      'update',
        message_id:   'some@id',
        content_type: 'text/html',
        body:         'update',
        internal:     false,
        sender:       Ticket::Article::Sender.find_by(name: 'Customer'),
        type:         Ticket::Article::Type.find_by(name: 'note'),
      )
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(1)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(3)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent2.id
      ticket1.owner_id = agent2.id
      ticket1.save!
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent2.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(3)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent1.id
      Ticket::Article.create!(
        ticket_id:    ticket1.id,
        from:         'some_sender@example.com',
        to:           'some_recipient@example.com',
        subject:      'update',
        message_id:   'some@id',
        content_type: 'text/html',
        body:         'update',
        internal:     false,
        sender:       Ticket::Article::Sender.find_by(name: 'Agent'),
        type:         Ticket::Article::Type.find_by(name: 'note'),
      )
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent1.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(4)
      expect(ticket1.tag_list).to eq([])
    end

    it 'automatically assigns the owner when the ticket priority has changed and a not-set owner pre-condition matches', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'aaa auto assignment',
        condition:            {
          'ticket.owner_id'    => {
            'operator'         => 'is',
            'pre_condition'    => 'not_set',
            'value'            => '',
            'value_completion' => '',
          },
          'ticket.priority_id' => {
            'operator'         => 'has changed',
            'pre_condition'    => '',
            'value'            => '2',
            'value_completion' => '',
          },
          'ticket.action'      => {
            'operator' => 'is',
            'value'    => 'update',
          },
        },
        perform:              {
          'ticket.owner_id' => {
            'pre_condition'    => 'current_user.id',
            'value'            => '',
            'value_completion' => '',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      groups = Group.where(name: 'Users')
      roles = Role.where(name: 'Agent')
      agent = User.create_or_update(
        login:         'agent@example.com',
        firstname:     'Trigger',
        lastname:      'Agent1',
        email:         'agent@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1 = Ticket.create!(
        title:         'test 123',
        # owner: agent,
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit

      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(1)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent.id
      Ticket::Article.create!(
        ticket_id:    ticket1.id,
        from:         'some_sender@example.com',
        to:           'some_recipient@example.com',
        subject:      'update',
        message_id:   'some@id',
        content_type: 'text/html',
        body:         'update',
        internal:     false,
        sender:       Ticket::Article::Sender.find_by(name: 'Agent'),
        type:         Ticket::Article::Type.find_by(name: 'note'),
      )
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(1)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent.id
      ticket1.priority = Ticket::Priority.find_by(name: '1 low')
      ticket1.save!
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('1 low')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent.id
      ticket1.owner_id = 1
      ticket1.save!
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(1)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('1 low')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent.id
      ticket1.owner_id = agent.id
      ticket1.save!
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('1 low')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])
    end

    it 'raises ticket priority when the customer is VIP, and leaves priority unaffected for non-VIP customers', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'aaa vip priority',
        condition:            {
          'customer.vip' => {
            'operator' => 'is',
            'value'    => true,
          },
        },
        perform:              {
          'ticket.priority_id' => {
            'value' => Ticket::Priority.find_by(name: '3 high').id,
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      groups = Group.where(name: 'Users')
      roles = Role.where(name: 'Agent')
      agent = User.create_or_update(
        login:         'agent@example.com',
        firstname:     'Trigger',
        lastname:      'Agent1',
        email:         'agent@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )
      roles = Role.where(name: 'Customer')
      customer = User.create_or_update(
        login:         'customer@example.com',
        firstname:     'Trigger',
        lastname:      'Customer1',
        email:         'customer@example.com',
        password:      'customerpw',
        vip:           true,
        active:        true,
        roles:         roles,
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1 = Ticket.create!(
        title:         'test 123',
        owner:         agent,
        customer:      customer,
        group:         Group.lookup(name: 'Users'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.customer_id).to eq(customer.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq([])

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.customer_id).to eq(customer.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('3 high')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq([])

      customer.vip = false
      customer.save!

      ticket2 = Ticket.create!(
        title:         'test 123',
        owner:         agent,
        customer:      customer,
        group:         Group.lookup(name: 'Users'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket2.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      expect(ticket2.title).to eq('test 123')
      expect(ticket2.group.name).to eq('Users')
      expect(ticket2.owner_id).to eq(agent.id)
      expect(ticket2.customer_id).to eq(customer.id)
      expect(ticket2.state.name).to eq('new')
      expect(ticket2.priority.name).to eq('2 normal')
      expect(ticket2.articles.count).to eq(1)
      expect(ticket2.tag_list).to eq([])

      TransactionDispatcher.commit

      ticket2.reload
      expect(ticket2.title).to eq('test 123')
      expect(ticket2.group.name).to eq('Users')
      expect(ticket2.owner_id).to eq(agent.id)
      expect(ticket2.customer_id).to eq(customer.id)
      expect(ticket2.state.name).to eq('new')
      expect(ticket2.priority.name).to eq('2 normal')
      expect(ticket2.articles.count).to eq(1)
      expect(ticket2.tag_list).to eq([])

    end

    it 'notifies the customer whenever the ticket owner changes to a specific value', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'aaa auto assignment',
        condition:            {
          'ticket.owner_id' => {
            'operator'         => 'has changed',
            'pre_condition'    => '',
            'value'            => '2',
            'value_completion' => '',
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some lala',
            'recipient' => 'ticket_customer',
            'subject'   => 'NEW OWNER (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      groups = Group.where(name: 'Users')
      roles = Role.where(name: 'Agent')
      agent1 = User.create_or_update(
        login:         'agent1@example.com',
        firstname:     'Trigger',
        lastname:      'Agent1',
        email:         'agent1@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )
      agent2 = User.create_or_update(
        login:         'agent2@example.com',
        firstname:     'Trigger',
        lastname:      'Agent2',
        email:         'agent2@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1 = Ticket.create!(
        title:         'test 123',
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit

      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(1)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent1.id
      ticket1.owner_id = agent1.id
      ticket1.save!
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent1.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent1.id
      ticket1.owner_id = agent1.id
      ticket1.save!
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent1.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent1.id
      ticket1.owner_id = agent2.id
      ticket1.save!
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent2.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(3)
      expect(ticket1.tag_list).to eq([])

    end

    it 'notifies the customer only for public (non-internal) agent notes, not internal notes or customer articles', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'aaa notify to customer on public note',
        condition:            {
          'article.internal'  => {
            'operator' => 'is',
            'value'    => 'false',
          },
          'article.sender_id' => {
            'operator' => 'is',
            'value'    => Ticket::Article::Sender.lookup(name: 'Agent').id,
          },
          'article.type_id'   => {
            'operator' => 'is',
            'value'    => [
              Ticket::Article::Type.lookup(name: 'note').id,
            ],
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some lala',
            'recipient' => 'ticket_customer',
            'subject'   => 'UPDATE (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      groups = Group.where(name: 'Users')
      roles = Role.where(name: 'Agent')
      agent = User.create_or_update(
        login:         'agent@example.com',
        firstname:     'Trigger',
        lastname:      'Agent1',
        email:         'agent@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )
      roles = Role.where(name: 'Customer')
      customer = User.create_or_update(
        login:         'customer@example.com',
        firstname:     'Trigger',
        lastname:      'Customer1',
        email:         'customer@example.com',
        password:      'customerpw',
        vip:           true,
        active:        true,
        roles:         roles,
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1 = Ticket.create!(
        title:         'test 123',
        owner:         agent,
        customer:      customer,
        group:         Group.lookup(name: 'Users'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.customer_id).to eq(customer.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      true,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.customer_id).to eq(customer.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(3)
      expect(ticket1.tag_list).to eq([])

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.customer_id).to eq(customer.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(5)
      expect(ticket1.tag_list).to eq([])

      ticket1.priority = Ticket::Priority.find_by(name: '3 high')
      ticket1.save!
      article = Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      true,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.customer_id).to eq(customer.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('3 high')
      expect(ticket1.articles.count).to eq(6)
      expect(ticket1.tag_list).to eq([])

      article.internal = false
      article.save!
      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.customer_id).to eq(customer.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('3 high')
      expect(ticket1.articles.count).to eq(6)
      expect(ticket1.tag_list).to eq([])

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      true,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.customer_id).to eq(customer.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('3 high')
      expect(ticket1.articles.count).to eq(7)
      expect(ticket1.tag_list).to eq([])
    end

    it 'notifies the customer on owner change while auto-replying to new and follow-up customer articles', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'aaa notify to customer on public note',
        condition:            {
          'ticket.owner_id' => {
            'operator'         => 'has changed',
            'pre_condition'    => 'current_user.id',
            'value'            => '',
            'value_completion' => '',
          }
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some lala',
            'recipient' => 'ticket_customer',
            'subject'   => 'UPDATE (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      described_class.create_or_update(
        name:          'auto reply (on new tickets)',
        condition:     {
          'ticket.action'     => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id'   => {
            'operator' => 'is not',
            'value'    => Ticket::State.lookup(name: 'closed').id,
          },
          'article.type_id'   => {
            'operator' => 'is',
            'value'    => [
              Ticket::Article::Type.lookup(name: 'email').id,
              Ticket::Article::Type.lookup(name: 'phone').id,
              Ticket::Article::Type.lookup(name: 'web').id,
            ],
          },
          'article.sender_id' => {
            'operator' => 'is',
            'value'    => Ticket::Article::Sender.lookup(name: 'Customer').id,
          },
        },
        perform:       {
          'notification.email' => {
            'body'      => '<div>Your request <b>(#{config.ticket_hook}#{ticket.number})</b> has been received and will be reviewed by our support staff.</div>
    <br/>
    <div>To provide additional information, please reply to this email or click on the following link (for initial login, please request a new password):
    <a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
    </div>
    <br/>
    <div>Your #{config.product_name} Team</div>
    <br/>
    <div><i><a href="https://zammad.com">Zammad</a>, your customer support system</i></div>',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})',
          },
        },
        active:        true,
        created_by_id: 1,
        updated_by_id: 1,
      )
      described_class.create_or_update(
        name:          'auto reply (on follow-up of tickets)',
        condition:     {
          'ticket.action'     => {
            'operator' => 'is',
            'value'    => 'update',
          },
          'article.sender_id' => {
            'operator' => 'is',
            'value'    => Ticket::Article::Sender.lookup(name: 'Customer').id,
          },
          'article.type_id'   => {
            'operator' => 'is',
            'value'    => [
              Ticket::Article::Type.lookup(name: 'email').id,
              Ticket::Article::Type.lookup(name: 'phone').id,
              Ticket::Article::Type.lookup(name: 'web').id,
            ],
          },
        },
        perform:       {
          'notification.email' => {
            'body'      => '<div>Your follow-up for <b>(#{config.ticket_hook}#{ticket.number})</b> has been received and will be reviewed by our support staff.</div>
    <br/>
    <div>To provide additional information, please reply to this email or click on the following link:
    <a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
    </div>
    <br/>
    <div>Your #{config.product_name} Team</div>
    <br/>
    <div><i><a href="https://zammad.com">Zammad</a>, your customer support system</i></div>',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your follow-up (#{ticket.title})',
          },
        },
        active:        true,
        created_by_id: 1,
        updated_by_id: 1,
      )

      groups = Group.where(name: 'Users')
      roles = Role.where(name: 'Agent')
      agent = User.create_or_update(
        login:         'agent@example.com',
        firstname:     'Trigger',
        lastname:      'Agent1',
        email:         'agent@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )
      roles = Role.where(name: 'Customer')
      customer = User.create_or_update(
        login:         'customer@example.com',
        firstname:     'Trigger',
        lastname:      'Customer1',
        email:         'customer@example.com',
        password:      'customerpw',
        vip:           true,
        active:        true,
        roles:         roles,
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1 = Ticket.create!(
        title:         'test 123',
        # owner: agent,
        customer:      customer,
        group:         Group.lookup(name: 'Users'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'web'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(1)
      expect(ticket1.customer_id).to eq(customer.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent.id
      ticket1.owner_id = agent.id
      ticket1.save!
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.customer_id).to eq(customer.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(3)
      expect(ticket1.tag_list).to eq([])

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'web'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(agent.id)
      expect(ticket1.customer_id).to eq(customer.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(5)
      expect(ticket1.tag_list).to eq([])

      UserInfo.current_user_id = agent.id
      ticket1.owner_id = 1
      ticket1.save!
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil

      ticket1.reload
      expect(ticket1.title).to eq('test 123')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.owner_id).to eq(1)
      expect(ticket1.customer_id).to eq(customer.id)
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(6)
      expect(ticket1.tag_list).to eq([])

    end

    it 'raises an error when a trigger condition contains an empty value' do
      expect do
        described_class.create_or_update(
          name:                 'aaa loop check',
          condition:            {
            'ticket.number' => {
              'operator' => 'contains',
              'value'    => '',
            },
          },
          perform:              {
            'notification.email' => {
              'body'      => 'some lala',
              'recipient' => 'ticket_customer',
              'subject'   => 'Thanks for your inquiry - loop check (#{ticket.title})!',
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )
      end.to raise_error(Exception)
    end

    it 'sends the \'article_last_sender\' notification to the article\'s reply_to address when present', :aggregate_failures do
      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
            'recipient' => 'article_last_sender',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      ticket1 = Ticket.create!(
        title:         "some <b>title</b>\n äöüß",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient+from@example.com',
        reply_to:      'some_recipient+reply_to@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.articles.count).to eq(2)
      auto_response = ticket1.articles.last
      expect(auto_response.from).to include('Zammad <zammad@localhost>')
      expect(auto_response.to).to include('some_recipient+reply_to@example.com')
    end

    it 'sends the \'article_last_sender\' notification to the article\'s from address when no reply_to is present', :aggregate_failures do
      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
            'recipient' => 'article_last_sender',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      ticket1 = Ticket.create!(
        title:         "some <b>title</b>\n äöüß",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender+from@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.articles.count).to eq(2)
      auto_response = ticket1.articles.last
      expect(auto_response.from).to include('Zammad <zammad@localhost>')
      expect(auto_response.to).to include('some_sender+from@example.com')
    end

    it 'sends the \'article_last_sender\' notification to the origin_by_id user\'s email when from/reply_to are absent', :aggregate_failures do
      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
            'recipient' => 'article_last_sender',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      roles = Role.where(name: 'Customer')
      customer1 = User.create_or_update(
        login:         'customer+origin_by_id@example.com',
        firstname:     'Trigger',
        lastname:      'Customer1',
        email:         'customer+origin_by_id@example.com',
        password:      'customerpw',
        active:        true,
        roles:         roles,
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
      ticket1 = Ticket.create!(
        title:         "some <b>title</b>\n äöüß",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        origin_by_id:  customer1.id,
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.articles.count).to eq(2)
      auto_response = ticket1.articles.last
      expect(auto_response.from).to include('Zammad <zammad@localhost>')
      expect(auto_response.to).to include('customer+origin_by_id@example.com')
    end

    it 'sends the \'article_last_sender\' notification to the created_by_id user\'s email when other sender fields are absent', :aggregate_failures do
      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
            'recipient' => 'article_last_sender',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      roles = Role.where(name: 'Customer')
      customer1 = User.create_or_update(
        login:         'customer+created_by_id@example.com',
        firstname:     'Trigger',
        lastname:      'Customer1',
        email:         'customer+created_by_id@example.com',
        password:      'customerpw',
        active:        true,
        roles:         roles,
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
      ticket1 = Ticket.create!(
        title:         "some <b>title</b>\n äöüß",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: customer1.id,
        created_by_id: customer1.id,
      )

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.articles.count).to eq(2)
      auto_response = ticket1.articles.last
      expect(auto_response.from).to include('Zammad <zammad@localhost>')
      expect(auto_response.to).to include('customer+created_by_id@example.com')
    end

    it 'notifies both the ticket owner and the article_last_sender recipients in a single trigger', :aggregate_failures do
      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
            'recipient' => %w[ticket_owner article_last_sender],
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      admin = User.create_or_update(
        login:         'admin+owner_recipient@example.com',
        firstname:     'Role',
        lastname:      "Admin#{RSpec.current_example.description}",
        email:         'admin+owner_recipient@example.com',
        password:      'adminpw',
        active:        true,
        roles:         Role.where(name: %w[Admin Agent]),
        groups:        Group.where(name: 'Users'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      ticket1 = Ticket.create!(
        title:         "some <b>title</b>\n äöüß",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        owner_id:      admin.id,
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient+from@example.com',
        reply_to:      'some_recipient+reply_to@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.articles.count).to eq(2)
      auto_response = ticket1.articles.last
      expect(auto_response.from).to include('Zammad <zammad@localhost>')
      expect(auto_response.to).to include('some_recipient+reply_to@example.com')
      expect(auto_response.to).to include('admin+owner_recipient@example.com')
    end

    it 'does not send a notification when the article\'s reply_to is not a valid email address', :aggregate_failures do
      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
            'recipient' => 'article_last_sender',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      ticket1 = Ticket.create!(
        title:         "some <b>title</b>\n äöüß",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient+from@example.com',
        reply_to:      'Blub blub blub some_recipient+reply_to@example',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.articles.count).to eq(1)
    end

    it 'does not get stuck in a notification loop when a trigger matches its own follow-up articles repeatedly, and stops after 21 iterations', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'aaa loop check',
        condition:            {
          'ticket.state_id'   => {
            'operator' => 'is',
            'value'    => Ticket::State.pluck(:id),
          },
          'article.sender_id' => {
            'operator' => 'is',
            'value'    => Ticket::Article::Sender.lookup(name: 'Customer').id,
          },
          'article.type_id'   => {
            'operator' => 'is',
            'value'    => [
              Ticket::Article::Type.lookup(name: 'email').id,
              Ticket::Article::Type.lookup(name: 'phone').id,
              Ticket::Article::Type.lookup(name: 'web').id,
            ],
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some lala',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry - loop check (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      ticket1 = Ticket.create!(
        title:         'loop try 1',
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_loop_sender@example.com',
        to:            'some_loop_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      ticket1.reload
      expect(ticket1.articles.count).to eq(1)

      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.articles.count).to eq(2)

      ticket1.priority = Ticket::Priority.lookup(name: '2 normal')
      ticket1.save!

      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.articles.count).to eq(2)

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_loop_sender@example.com',
        to:            'some_loop_recipient@example.com',
        subject:       'some subject 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.articles.count).to eq(4)
      expect(ticket1.articles[2].from).to eq('some_loop_sender@example.com')
      expect(ticket1.articles[3].to).to eq('nicole.braun@zammad.org')

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_loop_sender@example.com',
        to:            'some_loop_recipient@example.com',
        subject:       'some subject 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.articles.count).to eq(6)
      expect(ticket1.articles[4].from).to eq('some_loop_sender@example.com')
      expect(ticket1.articles[5].to).to eq('nicole.braun@zammad.org')

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_loop_sender@example.com',
        to:            'some_loop_recipient@example.com',
        subject:       'some subject 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.articles.count).to eq(8)
      expect(ticket1.articles[6].from).to eq('some_loop_sender@example.com')
      expect(ticket1.articles[7].to).to eq('nicole.braun@zammad.org')

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_loop_sender@example.com',
        to:            'some_loop_recipient@example.com',
        subject:       'some subject 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.articles.count).to eq(10)
      expect(ticket1.articles[8].from).to eq('some_loop_sender@example.com')
      expect(ticket1.articles[9].to).to eq('nicole.braun@zammad.org')

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_loop_sender@example.com',
        to:            'some_loop_recipient@example.com',
        subject:       'some subject 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.articles.count).to eq(12)
      expect(ticket1.articles[10].from).to eq('some_loop_sender@example.com')
      expect(ticket1.articles[11].to).to eq('nicole.braun@zammad.org')

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_loop_sender@example.com',
        to:            'some_loop_recipient@example.com',
        subject:       'some subject 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.articles.count).to eq(14)
      expect(ticket1.articles[12].from).to eq('some_loop_sender@example.com')
      expect(ticket1.articles[13].to).to eq('nicole.braun@zammad.org')

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_loop_sender@example.com',
        to:            'some_loop_recipient@example.com',
        subject:       'some subject 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.articles.count).to eq(16)
      expect(ticket1.articles[14].from).to eq('some_loop_sender@example.com')
      expect(ticket1.articles[15].to).to eq('nicole.braun@zammad.org')

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_loop_sender@example.com',
        to:            'some_loop_recipient@example.com',
        subject:       'some subject 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.articles.count).to eq(18)
      expect(ticket1.articles[16].from).to eq('some_loop_sender@example.com')
      expect(ticket1.articles[17].to).to eq('nicole.braun@zammad.org')

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_loop_sender@example.com',
        to:            'some_loop_recipient@example.com',
        subject:       'some subject 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.articles.count).to eq(20)
      expect(ticket1.articles[18].from).to eq('some_loop_sender@example.com')
      expect(ticket1.articles[19].to).to eq('nicole.braun@zammad.org')

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_loop_sender@example.com',
        to:            'some_loop_recipient@example.com',
        subject:       'some subject 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.articles.count).to eq(21)
      expect(ticket1.articles[20].from).to eq('some_loop_sender@example.com')

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_loop_sender@example.com',
        to:            'some_loop_recipient@example.com',
        subject:       'some subject 1234',
        message_id:    'some@id',
        content_type:  'text/html',
        body:          'some message <b>note</b><br>new line',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.articles.count).to eq(22)
      expect(ticket1.articles[21].from).to eq('some_loop_sender@example.com')

    end

    it 'ignores an invalid trigger condition value gracefully instead of blocking processing of other triggers', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      trigger1 = described_class.create_or_update(
        name:                 'aaa loop check',
        condition:            {
          'ticket.action' => {
            'operator' => 'is',
            'value'    => 'create',
          },
        },
        perform:              {
          'ticket.tags' => {
            'operator' => 'add',
            'value'    => 'xxx',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
      trigger1.update_column(:condition, {
                               'ticket.action'            => {
                                 'operator' => 'is',
                                 'value'    => 'create',
                               },
                               'ticket.first_response_at' => {
                                 'operator' => 'before (absolute)',
                                 'value'    => 'invalid invalid 4',
                               },
                             })
      expect(trigger1.condition['ticket.first_response_at']['value']).to eq('invalid invalid 4')

      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
          'ticket.priority_id' => {
            'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
          },
          'ticket.tags'        => {
            'operator' => 'add',
            'value'    => 'aa, kk',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      ticket1 = Ticket.create!(
        title:         "some <b>title</b>\n äöüß",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1.reload
      expect(ticket1.title).to eq('some <b>title</b>  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq([])

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('some <b>title</b>  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('3 high')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq(%w[aa kk])
      article1 = ticket1.articles.last
      expect(article1.from).to include('Zammad <zammad@localhost>')
      expect(article1.to).to include('nicole.braun@zammad.org')
      expect(article1.subject).to include('Thanks for your inquiry (some <b>title</b>  äöüß)!')
      expect(article1.body).to include('Braun<br>some &lt;b&gt;title&lt;/b&gt;')
      expect(article1.body).to include('&gt; some message &lt;b&gt;note&lt;/b&gt;<br>&gt; new line')
      expect(article1.content_type).to eq('text/html')

    end

    it 'adds sender-based tags and skips the auto-reply trigger when the ticket has none of the excluded tags', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 '100 add tag if sender 1',
        condition:            {
          'ticket.action' => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'article.from'  => {
            'operator' => 'contains',
            'value'    => 'sender1',
          },
        },
        perform:              {
          'ticket.tags' => {
            'operator' => 'add',
            'value'    => 'sender1',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      described_class.create_or_update(
        name:                 '200 add tag if sender 2',
        condition:            {
          'ticket.action' => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'article.from'  => {
            'operator' => 'contains',
            'value'    => 'sender2',
          },
        },
        perform:              {
          'ticket.tags' => {
            'operator' => 'add',
            'value'    => 'sender2',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      described_class.create_or_update(
        name:                 '300 auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          },
          'ticket.tags'     => {
            'operator' => 'contains one not',
            # 'operator' => 'contains all not',
            'value'    => 'sender1, sender2',
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      ticket1 = Ticket.create!(
        title:         'test 1',
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'sender1@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1.reload
      expect(ticket1.title).to eq('test 1')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq([])
      TransactionDispatcher.commit
      ticket1.reload
      expect(ticket1.title).to eq('test 1')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq(%w[sender1])

      ticket2 = Ticket.create!(
        title:         'test 2',
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket2.id,
        from:          'sender2@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket2.reload
      expect(ticket2.title).to eq('test 2')
      expect(ticket2.group.name).to eq('Users')
      expect(ticket2.state.name).to eq('new')
      expect(ticket2.priority.name).to eq('2 normal')
      expect(ticket2.articles.count).to eq(1)
      expect(ticket2.tag_list).to eq([])

      TransactionDispatcher.commit

      ticket2.reload
      expect(ticket2.title).to eq('test 2')
      expect(ticket2.group.name).to eq('Users')
      expect(ticket2.state.name).to eq('new')
      expect(ticket2.priority.name).to eq('2 normal')
      expect(ticket2.articles.count).to eq(1)
      expect(ticket2.tag_list).to eq(%w[sender2])

      ticket3 = Ticket.create!(
        title:         'test 3',
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      expect(ticket3).to be_truthy
      Ticket::Article.create!(
        ticket_id:     ticket3.id,
        from:          'sender0@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message <b>note</b>\nnew line",
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket3.reload
      expect(ticket3.title).to eq('test 3')
      expect(ticket3.group.name).to eq('Users')
      expect(ticket3.state.name).to eq('new')
      expect(ticket3.priority.name).to eq('2 normal')
      expect(ticket3.articles.count).to eq(1)
      expect(ticket3.tag_list).to eq([])
      TransactionDispatcher.commit
      ticket3.reload
      expect(ticket3.title).to eq('test 3')
      expect(ticket3.group.name).to eq('Users')
      expect(ticket3.state.name).to eq('new')
      expect(ticket3.priority.name).to eq('2 normal')
      expect(ticket3.articles.count).to eq(2)
      expect(ticket3.tag_list).to eq([])
      ticket3.articles.last

    end

    it 'fires or skips an auto-reply trigger based on whether the article body contains or does not contain a given string', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          },
          'article.body'    => {
            'operator' => 'contains',
            'value'    => 'hello',
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
          'ticket.tags'        => {
            'operator' => 'add',
            'value'    => 'aa, kk',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      ticket1 = Ticket.create!(
        title:         'test 1',
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          'some message <b>note</b> hello ',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1.reload
      expect(ticket1.title).to eq('test 1')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.tag_list).to eq([])

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('test 1')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.articles.count).to eq(2)
      expect(ticket1.tag_list).to eq(%w[aa kk])
      article1 = ticket1.articles.last
      expect(article1.from).to include('Zammad <zammad@localhost>')
      expect(article1.to).to include('nicole.braun@zammad.org')
      expect(article1.subject).to include('Thanks for your inquiry (test 1)!')
      expect(article1.body).to include('some message')
      expect(article1.body).to include('&gt; some message &lt;b&gt;note&lt;/b&gt; hello')
      expect(article1.content_type).to eq('text/html')

      ticket2 = Ticket.create!(
        title:         'test 1',
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket2.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          'some message <b>note</b>',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket2.reload
      expect(ticket2.title).to eq('test 1')
      expect(ticket2.group.name).to eq('Users')
      expect(ticket2.state.name).to eq('new')
      expect(ticket2.priority.name).to eq('2 normal')
      expect(ticket2.articles.count).to eq(1)
      expect(ticket2.tag_list).to eq([])

      TransactionDispatcher.commit

      ticket2.reload
      expect(ticket2.title).to eq('test 1')
      expect(ticket2.group.name).to eq('Users')
      expect(ticket2.state.name).to eq('new')
      expect(ticket2.articles.count).to eq(1)
      expect(ticket2.tag_list).to eq(%w[])

      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          },
          'article.body'    => {
            'operator' => 'contains not',
            'value'    => 'hello',
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
          'ticket.tags'        => {
            'operator' => 'add',
            'value'    => 'aa, kk',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      ticket3 = Ticket.create!(
        title:         'test 1',
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket3.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          'some message <b>note</b> hello ',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket3.reload
      expect(ticket3.title).to eq('test 1')
      expect(ticket3.group.name).to eq('Users')
      expect(ticket3.state.name).to eq('new')
      expect(ticket3.priority.name).to eq('2 normal')
      expect(ticket3.articles.count).to eq(1)
      expect(ticket3.tag_list).to eq([])

      TransactionDispatcher.commit

      ticket3.reload
      expect(ticket3.title).to eq('test 1')
      expect(ticket3.group.name).to eq('Users')
      expect(ticket3.state.name).to eq('new')
      expect(ticket3.articles.count).to eq(1)
      expect(ticket3.tag_list).to eq(%w[])

      ticket4 = Ticket.create!(
        title:         'test 1',
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        ticket_id:     ticket4.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          'some message <b>note</b> 2',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket4.reload
      expect(ticket4.title).to eq('test 1')
      expect(ticket4.group.name).to eq('Users')
      expect(ticket4.state.name).to eq('new')
      expect(ticket4.priority.name).to eq('2 normal')
      expect(ticket4.articles.count).to eq(1)
      expect(ticket4.tag_list).to eq([])

      TransactionDispatcher.commit

      ticket4.reload
      expect(ticket4.title).to eq('test 1')
      expect(ticket4.group.name).to eq('Users')
      expect(ticket4.state.name).to eq('new')
      expect(ticket4.articles.count).to eq(2)
      expect(ticket4.tag_list).to eq(%w[aa kk])
      article4 = ticket4.articles.last
      expect(article4.from).to include('Zammad <zammad@localhost>')
      expect(article4.to).to include('nicole.braun@zammad.org')
      expect(article4.subject).to include('Thanks for your inquiry (test 1)!')
      expect(article4.body).to include('some message')
      expect(article4.body).to include('&gt; some message &lt;b&gt;note&lt;/b&gt; 2')
      expect(article4.content_type).to eq('text/html')

    end

    it 'adds tags on owner change only for tickets that do not already carry the exclusion tag, avoiding infinite tag-triggered loops', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      roles = Role.where(name: 'Agent')
      groups = Group.where(name: 'Users')
      agent1 = User.create_or_update(
        login:         'agent-has-changed@example.com',
        firstname:     'Has Changed',
        lastname:      'Agent1',
        email:         'agent-has-changed@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )

      agent2 = User.create_or_update(
        login:         'agent-has-changed2@example.com',
        firstname:     'Has Changed',
        lastname:      'Agent2',
        email:         'agent-has-changed2@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )

      # multi tag trigger with changed owner
      described_class.create_or_update(
        name:                 'change owner',
        condition:            {
          'ticket.owner_id' => {
            'operator' => 'has changed',
          },
          'ticket.tags'     => {
            'operator' => 'contains one not',
            'value'    => 'nosendmail test123'
          }
        },
        perform:              {
          'ticket.tags'        => {
            'operator' => 'add',
            'value'    => '123'
          },
          'notification.email' => {
            'body'      => 'some lala',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry - 1234 check (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      # single tag trigger with changed owner
      described_class.create_or_update(
        name:                 'change owner',
        condition:            {
          'ticket.owner_id' => {
            'operator' => 'has changed',
          },
          'ticket.tags'     => {
            'operator' => 'contains one not',
            'value'    => 'nosendmail2',
          }
        },
        perform:              {
          'ticket.tags'        => {
            'operator' => 'add',
            'value'    => '123'
          },
          'notification.email' => {
            'body'      => 'some lala',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry - 1234 check (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      ticket1 = Ticket.create!(
        title:         "some title\n äöüß",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(0)
      expect(agent1.login).to eq('agent-has-changed@example.com')
      expect(ticket1.tag_list).to eq([])

      ticket2 = Ticket.create!(
        title:         "some title\n äöüß",
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      expect(ticket2.title).to eq('some title  äöüß')
      expect(ticket2.group.name).to eq('Users')
      expect(ticket2.state.name).to eq('new')
      expect(ticket2.priority.name).to eq('2 normal')
      expect(ticket2.articles.count).to eq(0)
      expect(agent1.login).to eq('agent-has-changed@example.com')
      expect(ticket1.tag_list).to eq([])

      # control test - should pass
      # create common object tag
      Tag::Object.create_or_update(name: 'Ticket')

      # add tag
      ticket1.tag_add('thisisthebestjob', agent1.id)

      # change owner
      ticket1.owner_id = agent1.id
      ticket1.save!

      TransactionDispatcher.commit

      # this will add a tag by trigger
      ticket1.reload
      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1) # articles.count must be 1 if the tag is added
      expect(agent1.login).to eq('agent-has-changed@example.com')
      expect(ticket1.tag_list).to eq(%w[thisisthebestjob 123])

      # add tag nosendmail (to test the bug)
      ticket1.tag_add('nosendmail', agent2.id)

      # change owner
      ticket1.owner_id = agent2.id
      ticket1.save!

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(2) # articles.count must be 0 if adding tag is skipped
      expect(agent2.login).to eq('agent-has-changed2@example.com')
      expect(ticket1.tag_list).to eq(%w[thisisthebestjob 123 nosendmail])

      # add tag (to test the bug)
      ticket1.tag_add('test123', agent2.id)

      # change owner
      ticket1.owner_id = agent1.id
      ticket1.save!

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('some title  äöüß')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(3) # articles.count must be 0 if adding tag is skipped
      expect(agent1.login).to eq('agent-has-changed@example.com')
      expect(ticket1.tag_list).to eq(%w[thisisthebestjob 123 nosendmail test123])

      # add tag single tag 'nosendmail2' (to test the bug)
      ticket2.tag_add('nosendmail2', agent1.id)

      # change owner
      ticket2.owner_id = agent1.id
      ticket2.save!

      TransactionDispatcher.commit

      ticket2.reload
      expect(ticket2.title).to eq('some title  äöüß')
      expect(ticket2.group.name).to eq('Users')
      expect(ticket2.state.name).to eq('new')
      expect(ticket2.priority.name).to eq('2 normal')
      expect(ticket2.articles.count).to eq(0) # articles.count must be 0 if adding tag is skipped
      expect(agent1.login).to eq('agent-has-changed@example.com')
      expect(ticket2.tag_list).to eq(['nosendmail2'])

    end

    it 'extracts the reply e-mail address correctly from a from-header containing umlauts', :aggregate_failures do
      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
            'recipient' => 'article_last_sender',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      ticket1 = Ticket.create!(
        title:         'test 1',
        group:         Group.lookup(name: 'Users'),
        customer:      User.lookup(email: 'nicole.braun@zammad.org'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'Sabine Schütz <some_sender@example.com>',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          'some message <b>note</b> hello ',
        internal:      false,
        sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
        type:          Ticket::Article::Type.find_by(name: 'email'),
        updated_by_id: 1,
        created_by_id: 1,
      )

      ticket1.reload
      expect(ticket1.title).to eq('test 1')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.priority.name).to eq('2 normal')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.articles.first.from).to eq('Sabine Schütz <some_sender@example.com>')
      expect(ticket1.tag_list).to eq([])

      TransactionDispatcher.commit

      ticket1.reload
      expect(ticket1.title).to eq('test 1')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.articles.count).to eq(2)
      article1 = ticket1.articles.last
      expect(article1.from).to include('Zammad <zammad@localhost>')
      expect(article1.to).to include('some_sender@example.com')
      expect(article1.subject).to include('Thanks for your inquiry (test 1)!')
      expect(article1.body).to include('some message')
      expect(article1.body).to include('&gt; some message &lt;b&gt;note&lt;/b&gt; hello')
      expect(article1.content_type).to eq('text/html')

    end

    it 'extracts a single reply e-mail address from a from-header containing two sender addresses', :aggregate_failures do
      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
            'recipient' => 'article_last_sender',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      ticket1, _article1, _user, _mail = Channel::EmailParser.new.process({}, Rails.root.join('test/data/mail/mail065.box').read)

      expect(ticket1.title).to eq('aaäöüßad asd')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.articles.count).to eq(2)
      article1 = ticket1.articles.last
      expect(article1.from).to include('Zammad <zammad@localhost>')
      expect(article1.to).to include('smith@example.com')
      expect(article1.subject).to include('Thanks for your inquiry (aaäöüßad asd)!')
      expect(article1.body).to include('some text<br><br>aaäöüßad asd')
      expect(article1.content_type).to eq('text/html')

    end

    it 'attaches inline (cid) images referenced in the notification body as email attachments', :aggregate_failures do
      described_class.create_or_update(
        name:                 'auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          },
        },
        perform:              {
          'notification.email' => {
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}<br><img tabindex="0" style="width: 192px; height: 192px" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCADAAMADAREAAhEBAxEB/8QAHgABAAICAwEBAQAAAAAAAAAAAAcICQoFBgsDAQT/xAA7EAAABwEAAQMCAgYJAgcAAAAAAQIDBAUGBwgJERITIQoUFRciMXa1FiMyNzg5QVF3JLIYGSc1QkVh/8QAHQEBAAICAwEBAAAAAAAAAAAAAAQFAwYCBwgBCf/EAEURAAICAgEDAgMEBAkLBAMAAAECAAMEEQUGEiETMQciQQgUMlEjYXF2FTM1QnJzgZGzFjY3OFJiobGytLUXGILBJTRD/9oADAMBAAIRAxEAPwDU/G4SPARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARLM+HPi5uvNDyU5T4086cbiaXp+iTU/piTGflwM3TxYsiyv9PZx4xk+5WZ+nhzLSelk/qnGjLJslLNKT++Atjk6Wquy1z/uo">',
            'recipient' => 'article_last_sender',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      ticket1, _article1, _user, _mail = Channel::EmailParser.new.process({}, Rails.root.join('test/data/mail/mail065.box').read)

      expect(ticket1.title).to eq('aaäöüßad asd')
      expect(ticket1.group.name).to eq('Users')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.articles.count).to eq(2)
      article1 = ticket1.articles.last
      expect(article1.from).to include('Zammad <zammad@localhost>')
      expect(article1.to).to include('smith@example.com')
      expect(article1.subject).to include('Thanks for your inquiry (aaäöüßad asd)!')
      expect(article1.body).to match(%r{.+cid:.+?@zammad.example.com.+})
      expect(article1.attachments.count).to eq(1)
      expect(article1.attachments[0].size).to eq('789')
      expect(article1.content_type).to eq('text/html')
    end
  end
end
