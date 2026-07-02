# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Trigger, type: :model do
  describe 'extended trigger behaviour' do
    before do
      described_class.destroy_all # Default DB state includes three sample triggers
      Setting.set('system_init_done', true)
      Setting.set('ticket_trigger_recursive', true)
    end

    describe 'recursive triggers on ticket creation via email' do
      let(:email_raw_string) do
        <<~RAW
          From: me@example.com
          To: customer@example.com
          Subject: some new subject

          Some Text
        RAW
      end

      it 'executes a follow-up trigger matching the outcome of a previous trigger', :aggregate_failures do
        described_class.create!(
          name:                 '1) set prio to 3 high',
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
            'ticket.priority_id' => {
              'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )

        described_class.create!(
          name:                 '2) set state to closed',
          condition:            {
            'ticket.action'      => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '3 high').id.to_s,
            },
          },
          perform:              {
            'ticket.state_id' => {
              'value' => Ticket::State.lookup(name: 'closed').id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )

        ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
        expect(ticket_p.title).to eq('some new subject')
        expect(ticket_p.group.name).to eq('Users')
        expect(ticket_p.priority.name).to eq('3 high')
        expect(ticket_p.state.name).to eq('closed')

        expect(ticket_p.articles.count).to eq(1)
      end

      it 'does not loop endlessly when triggers form a cycle', :aggregate_failures do
        described_class.create!(
          name:                 '1) set prio to 3 high',
          condition:            {
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
            },
          },
          perform:              {
            'ticket.priority_id' => {
              'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
            },
            'ticket.state_id'    => {
              'value' => Ticket::State.lookup(name: 'closed').id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )

        described_class.create!(
          name:                 '2) set prio to 1 low',
          condition:            {
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '3 high').id.to_s,
            },
          },
          perform:              {
            'ticket.priority_id' => {
              'value' => Ticket::Priority.lookup(name: '1 low').id.to_s,
            },
            'ticket.state_id'    => {
              'value' => Ticket::State.lookup(name: 'open').id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )

        described_class.create!(
          name:                 '3) set prio to 3 high',
          condition:            {
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '1 low').id.to_s,
            },
          },
          perform:              {
            'ticket.priority_id' => {
              'value' => Ticket::Priority.lookup(name: '2 normal').id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )

        ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
        expect(ticket_p.title).to eq('some new subject')
        expect(ticket_p.group.name).to eq('Users')
        expect(ticket_p.priority.name).to eq('2 normal')
        expect(ticket_p.state.name).to eq('open')

        expect(ticket_p.articles.count).to eq(1)
      end

      it 'does not execute a next trigger when a previous trigger changed the matching conditions', :aggregate_failures do
        described_class.create!(
          name:                 '1) set prio to 3 high',
          condition:            {
            'ticket.action'      => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
            },
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

        described_class.create!(
          name:                 '2) set state to open',
          condition:            {
            'ticket.action'      => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
            },
          },
          perform:              {
            'ticket.state_id' => {
              'value' => Ticket::State.lookup(name: 'open').id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )

        described_class.create!(
          name:                 '3) set state to closed',
          condition:            {
            'ticket.action'      => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
            },
            'ticket.state_id'    => {
              'operator' => 'is',
              'value'    => Ticket::State.lookup(name: 'open').id.to_s,
            },
          },
          perform:              {
            'ticket.state_id' => {
              'value' => Ticket::State.lookup(name: 'closed').id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )

        ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
        expect(ticket_p.title).to eq('some new subject')
        expect(ticket_p.group.name).to eq('Users')
        expect(ticket_p.priority.name).to eq('3 high')
        expect(ticket_p.state.name).to eq('new')

        expect(ticket_p.articles.count).to eq(1)
      end

      it 'executes a next trigger when a previous trigger changed the ticket to match - case 1', :aggregate_failures do
        described_class.create!(
          name:                 '1) set state to closed',
          condition:            {
            'ticket.action'      => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '3 high').id.to_s,
            },
            'ticket.state_id'    => {
              'operator' => 'is',
              'value'    => Ticket::State.lookup(name: 'open').id.to_s,
            },
          },
          perform:              {
            'ticket.state_id' => {
              'value' => Ticket::State.lookup(name: 'closed').id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )

        described_class.create!(
          name:                 '2) set prio to 3 high',
          condition:            {
            'ticket.action'      => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
            },
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

        described_class.create!(
          name:                 '3) set state to open',
          condition:            {
            'ticket.action' => {
              'operator' => 'is',
              'value'    => 'create',
            },
          },
          perform:              {
            'ticket.state_id' => {
              'value' => Ticket::State.lookup(name: 'open').id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )

        ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)

        expect(ticket_p.title).to eq('some new subject')
        expect(ticket_p.group.name).to eq('Users')
        expect(ticket_p.priority.name).to eq('3 high')
        expect(ticket_p.state.name).to eq('closed')
        expect(ticket_p.articles.count).to eq(1)
      end

      it 'executes a next trigger when a previous trigger changed the ticket to match - case 2', :aggregate_failures do
        described_class.create!(
          name:                 '1) set prio to 3 high',
          condition:            {
            'ticket.action'      => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
            },
            'ticket.state_id'    => {
              'operator' => 'is',
              'value'    => Ticket::State.lookup(name: 'closed').id.to_s,
            },
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

        described_class.create!(
          name:                 '2) set state to closed',
          condition:            {
            'ticket.action'      => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
            },
            'ticket.state_id'    => {
              'operator' => 'is',
              'value'    => Ticket::State.lookup(name: 'open').id.to_s,
            },
          },
          perform:              {
            'ticket.state_id' => {
              'value' => Ticket::State.lookup(name: 'closed').id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )

        described_class.create!(
          name:                 '3) set state to open',
          condition:            {
            'ticket.action' => {
              'operator' => 'is',
              'value'    => 'create',
            },
          },
          perform:              {
            'ticket.state_id' => {
              'value' => Ticket::State.lookup(name: 'open').id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )

        ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)

        expect(ticket_p.title).to eq('some new subject')
        expect(ticket_p.group.name).to eq('Users')
        expect(ticket_p.priority.name).to eq('3 high')
        expect(ticket_p.state.name).to eq('closed')

        expect(ticket_p.articles.count).to eq(1)
      end
    end

    describe 'trigger based move', performs_jobs: true do
      it 'moves the ticket through the groups and notifies only the agents of the final group', :aggregate_failures do
        group1 = Group.create!(
          name:          'Group 1',
          active:        true,
          email_address: create(:email_address),
          created_by_id: 1,
          updated_by_id: 1,
        )
        group2 = Group.create!(
          name:          'Group 2',
          active:        true,
          email_address: create(:email_address),
          created_by_id: 1,
          updated_by_id: 1,
        )
        group3 = Group.create!(
          name:          'Group 3',
          active:        true,
          email_address: create(:email_address),
          created_by_id: 1,
          updated_by_id: 1,
        )
        roles = Role.where(name: 'Agent')
        user1 = User.create!(
          login:         'trigger1@example.org',
          firstname:     'trigger1',
          lastname:      'trigger1',
          email:         'trigger1@example.org',
          password:      'some_pass',
          active:        true,
          groups:        [group1],
          roles:         roles,
          created_by_id: 1,
          updated_by_id: 1,
        )
        user2 = User.create!(
          login:         'trigger2@example.org',
          firstname:     'trigger2',
          lastname:      'trigger2',
          email:         'trigger2@example.org',
          password:      'some_pass',
          active:        true,
          groups:        [group2],
          roles:         roles,
          created_by_id: 1,
          updated_by_id: 1,
        )

        # trigger, move ticket created in group1 into group3 and then into group2
        described_class.create_or_update(
          name:                 '1 dispatch',
          condition:            {
            'ticket.action'   => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.group_id' => {
              'operator' => 'is',
              'value'    => group3.id.to_s,
            },
            'ticket.state_id' => {
              'operator' => 'is',
              'value'    => Ticket::State.lookup(name: 'new').id.to_s,
            },
          },
          perform:              {
            'ticket.group_id' => {
              'value' => group2.id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )
        described_class.create_or_update(
          name:                 '2 dispatch',
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
            'ticket.group_id' => {
              'value' => group3.id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )

        ticket1 = Ticket.create!(
          title:         '123',
          group:         group1,
          customer_id:   2,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(ticket1).to be_truthy

        expect(ticket1.title).to eq('123')
        expect(ticket1.group.name).to eq(group1.name)
        expect(ticket1.state.name).to eq('new')

        Ticket::Article.create!(
          ticket_id:     ticket1.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
          type:          Ticket::Article::Type.find_by(name: 'email'),
          updated_by_id: 1,
          created_by_id: 1,
        )

        # verfiy if agent1 got no notifcation
        expect(NotificationFactory::Mailer.already_sent?(ticket1, user1, 'email')).to eq(0)

        # verfiy if agent2 got no notifcation
        expect(NotificationFactory::Mailer.already_sent?(ticket1, user2, 'email')).to eq(0)

        perform_enqueued_jobs commit_transaction: true

        ticket1.reload
        expect(ticket1.title).to eq('123')
        expect(ticket1.group.name).to eq(group2.name)
        expect(ticket1.state.name).to eq('new')
        expect(ticket1.priority.name).to eq('2 normal')
        expect(ticket1.articles.count).to eq(1)

        # verfiy if agent1 got no notifcation
        expect(NotificationFactory::Mailer.already_sent?(ticket1, user1, 'email')).to eq(0)

        # verfiy if agent2 got notifcation
        expect(NotificationFactory::Mailer.already_sent?(ticket1, user2, 'email')).to eq(1)
      end
    end

    describe 'recursive trigger loop check', performs_jobs: true do
      it 'stops recursive trigger processing based on ticket_trigger_recursive_max_loop setting', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        Setting.set('ticket_trigger_recursive_max_loop', 2)
        described_class.create!(
          name:                 '000',
          condition:            {
            'ticket.action'      => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '1 low').id.to_s,
            },
          },
          perform:              {
            'ticket.state_id' => {
              'value' => Ticket::State.lookup(name: 'closed').id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )
        described_class.create!(
          name:                 '001',
          condition:            {
            'ticket.action'      => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '3 high').id.to_s,
            },
          },
          perform:              {
            'ticket.priority_id' => {
              'value' => Ticket::Priority.lookup(name: '1 low').id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )
        described_class.create!(
          name:                 '002',
          condition:            {
            'ticket.action'      => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
            },
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
        group1 = Group.find_by(name: 'Users')
        ticket1 = Ticket.create!(
          title:         '123',
          group:         group1,
          customer_id:   2,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(ticket1).to be_truthy

        expect(ticket1.title).to eq('123')
        expect(ticket1.group.name).to eq(group1.name)
        expect(ticket1.state.name).to eq('new')

        Ticket::Article.create!(
          ticket_id:     ticket1.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
          type:          Ticket::Article::Type.find_by(name: 'email'),
          updated_by_id: 1,
          created_by_id: 1,
        )

        perform_enqueued_jobs commit_transaction: true

        ticket1.reload
        expect(ticket1.title).to eq('123')
        expect(ticket1.state.name).to eq('new')
        expect(ticket1.priority.name).to eq('1 low')
        expect(ticket1.articles.count).to eq(1)

        Setting.set('ticket_trigger_recursive_max_loop', 3)

        ticket1 = Ticket.create!(
          title:         '123',
          group:         group1,
          customer_id:   2,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(ticket1).to be_truthy

        expect(ticket1.title).to eq('123')
        expect(ticket1.group.name).to eq(group1.name)
        expect(ticket1.state.name).to eq('new')

        Ticket::Article.create!(
          ticket_id:     ticket1.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
          type:          Ticket::Article::Type.find_by(name: 'email'),
          updated_by_id: 1,
          created_by_id: 1,
        )

        perform_enqueued_jobs commit_transaction: true

        ticket1.reload
        expect(ticket1.title).to eq('123')
        expect(ticket1.state.name).to eq('closed')
        expect(ticket1.priority.name).to eq('1 low')
        expect(ticket1.articles.count).to eq(1)
      end
    end

    describe 'recursive trigger with auto responder' do
      it 'sends the auto responder of the target group after the ticket was moved by a trigger', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        group1 = Group.create!(
          name:          'Group dispatch',
          active:        true,
          created_by_id: 1,
          updated_by_id: 1,
        )
        group2 = Group.create!(
          name:          'Group with auto responder',
          active:        true,
          email_address: create(:email_address),
          created_by_id: 1,
          updated_by_id: 1,
        )

        described_class.create!(
          name:                 "002 - move ticket to #{group2.name}",
          condition:            {
            'ticket.action'          => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.group_id'        => {
              'operator' => 'is',
              'value'    => group1.id.to_s,
            },
            'ticket.organization_id' => {
              'operator'      => 'is',
              'pre_condition' => 'specific',
              'value'         => User.lookup(email: 'nicole.braun@zammad.org').organization_id.to_s,
            }
          },
          perform:              {
            'ticket.group_id' => {
              'value' => group2.id.to_s,
            },
          },
          disable_notification: true,
          active:               true,
          created_by_id:        1,
          updated_by_id:        1,
        )

        described_class.create_or_update(
          name:                 "001 auto reply for tickets in group #{group1.name}",
          condition:            {
            'ticket.action'   => {
              'operator' => 'is',
              'value'    => 'create',
            },
            'ticket.state_id' => {
              'operator' => 'is',
              'value'    => Ticket::State.lookup(name: 'new').id.to_s,
            },
            'ticket.group_id' => {
              'operator' => 'is not',
              'value'    => group1.id.to_s,
            },
          },
          perform:              {
            'notification.email' => {
              'body'      => "some text<br>\#{ticket.customer.lastname}<br>\#{ticket.title}<br>\#{article.body}",
              'recipient' => 'ticket_customer',
              'subject'   => "Thanks for your inquiry (\#{ticket.title})!",
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
          group:         group1,
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
          sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
          type:          Ticket::Article::Type.find_by(name: 'web'),
          updated_by_id: 1,
          created_by_id: 1,
        )

        ticket1.reload
        expect(ticket1.title).to eq('some <b>title</b>  äöüß')
        expect(ticket1.group.name).to eq('Group dispatch')
        expect(ticket1.state.name).to eq('new')
        expect(ticket1.priority.name).to eq('2 normal')
        expect(ticket1.articles.count).to eq(1)
        expect(ticket1.tag_list).to eq([])

        TransactionDispatcher.commit

        ticket1.reload
        expect(ticket1.title).to eq('some <b>title</b>  äöüß')
        expect(ticket1.group.name).to eq('Group with auto responder')
        expect(ticket1.state.name).to eq('new')
        expect(ticket1.priority.name).to eq('3 high')
        expect(ticket1.articles.count).to eq(2)
        expect(ticket1.tag_list).to eq(%w[aa kk])

        email_raw = <<~RAW
          From: nicole.braun@zammad.org
          To: zammad@example.com
          Subject: test 1
          X-Zammad-Ticket-Group: #{group1.name}

          test 1
        RAW

        ticket2, _article2, _user2 = Channel::EmailParser.new.process({ trusted: true }, email_raw)

        expect(ticket2.title).to eq('test 1')
        expect(ticket2.group.name).to eq('Group with auto responder')
        expect(ticket2.state.name).to eq('new')
        expect(ticket2.priority.name).to eq('3 high')
        expect(ticket2.articles.count).to eq(2)
        expect(ticket2.tag_list).to eq(%w[aa kk])
      end
    end
  end
end
