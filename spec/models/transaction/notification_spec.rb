# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'models/concerns/checks_human_changes_examples'

RSpec.describe Transaction::Notification, type: :model do
  describe 'pending ticket reminder repeats after midnight at selected time zone', time_zone: 'UTC' do
    let(:group)  { create(:group) }
    let(:user)   { create(:agent) }
    let(:ticket) { create(:ticket, owner: user, state_name: 'open', pending_time: Time.current) }

    before do
      travel_to DateTime.parse('2024-11-15T12:00:00Z')

      user.groups << group
      ticket

      Setting.set('timezone_default', 'America/Santiago')
      run(ticket, user, 'reminder_reached')
      OnlineNotification.destroy_all
    end

    it 'notification not sent at UTC midnight' do
      travel_to DateTime.parse('2024-11-16T00:01:00Z')

      expect { run(ticket, user, 'reminder_reached') }.not_to change(OnlineNotification, :count)
    end

    it 'notification sent at selected time zone midnight' do
      travel_to DateTime.parse('2024-11-16T03:01:00Z')

      expect { run(ticket, user, 'reminder_reached') }.to change(OnlineNotification, :count).by(1)
    end
  end

  # https://github.com/zammad/zammad/issues/4066
  describe 'notification sending reason may be fully translated' do
    let(:group) { create(:group) }
    let(:user)      { create(:agent, groups: [group]) }
    let(:ticket)    { create(:ticket, owner: user, state_name: 'open', pending_time: Time.current) }
    let(:reason_en) { 'You are receiving this because you are the owner of this ticket.' }
    let(:reason_de) do
      Translation.translate('de-de', reason_en).tap do |translated|
        expect(translated).not_to eq(reason_en) # rubocop:disable RSpec/ExpectInLet
      end
    end

    before do
      allow(NotificationFactory::Mailer).to receive(:deliver)
    end

    it 'notification includes English footer' do
      run(ticket, user, 'reminder_reached')

      expect(NotificationFactory::Mailer)
        .to have_received(:deliver)
        .with hash_including body: %r{#{reason_en}}
    end

    context 'when locale set to Deutsch' do
      before do
        user.preferences[:locale] = 'de-de'
        user.save
      end

      it 'notification includes German footer' do
        run(ticket, user, 'reminder_reached')

        expect(NotificationFactory::Mailer)
          .to have_received(:deliver)
          .with hash_including body: %r{#{reason_de}}
      end
    end
  end

  describe '#ooo_replacements' do
    subject(:notification_instance) { build(ticket, user) }

    let(:group)         { create(:group) }
    let(:user)          { create(:agent, :ooo, :groupable, ooo_agent: replacement_1, group: group) }
    let(:ticket)        { create(:ticket, owner: user, group: group, state_name: 'open', pending_time: Time.current) }

    context 'when replacement has access' do
      let(:replacement_1) { create(:agent, :groupable, group: group) }

      it 'is added to list' do
        replacements = Set.new

        ooo(notification_instance, user, replacements: replacements)

        expect(replacements).to include replacement_1
      end

      context 'when replacement has replacement' do
        let(:replacement_1) { create(:agent, :ooo, :groupable, ooo_agent: replacement_2, group: group) }
        let(:replacement_2) { create(:agent, :groupable, group: group) }

        it 'replacement\'s replacement added to list' do
          replacements = Set.new

          ooo(notification_instance, user, replacements: replacements)

          expect(replacements).to include replacement_2
        end

        it 'intermediary replacement is not in list' do
          replacements = Set.new

          ooo(notification_instance, user, replacements: replacements)

          expect(replacements).not_to include replacement_1
        end
      end
    end

    context 'when replacement does not have access' do
      let(:replacement_1) { create(:agent) }

      it 'is not added to list' do
        replacements = Set.new

        ooo(notification_instance, user, replacements: replacements)

        expect(replacements).not_to include replacement_1
      end

      context 'when replacement has replacement with access' do
        let(:replacement_1) { create(:agent, :ooo, ooo_agent: replacement_2) }
        let(:replacement_2) { create(:agent, :groupable, group: group) }

        it 'his replacement may be added' do
          replacements = Set.new

          ooo(notification_instance, user, replacements: replacements)

          expect(replacements).to include replacement_2
        end
      end
    end
  end

  describe 'SMTP errors' do
    let(:group)    { create(:group) }
    let(:user)     { create(:agent, groups: [group]) }
    let(:ticket)   { create(:ticket, owner: user, state_name: 'open', pending_time: Time.current) }
    let(:response) { Net::SMTP::Response.new(response_status_code, 'mocked SMTP response') }
    let(:error)    { Net::SMTPFatalError.new(response) }

    before do
      allow_any_instance_of(Net::SMTP).to receive(:start).and_raise(error)

      Service::System::SetEmailNotificationConfiguration
        .execute(
          adapter:           'smtp',
          new_configuration: {}
        )
    end

    context 'when there is a problem with the sending SMTP server' do
      let(:response_status_code) { 535 }

      it 'raises an eroror' do
        expect { run(ticket, user, 'reminder_reached') }
          .to raise_error(Channel::DeliveryError)
      end
    end

    context 'when there is a problem with the receiving SMTP server' do
      let(:response_status_code) { 550 }

      it 'logs the information about failed email delivery' do
        allow(Rails.logger).to receive(:info)
        run(ticket, user, 'reminder_reached')
        expect(Rails.logger).to have_received(:info)
      end
    end
  end

  describe 'daily locks behaviour' do
    let(:group)      { create(:group) }
    let(:user)       { create(:agent, groups: [group]) }
    let(:other_user) { create(:agent, groups: [group]) }
    let(:ticket)     { create(:ticket, group:, state_name: 'open', pending_time: Time.current) }
    let(:instance)   { build(ticket, user, 'reminder_reached') }

    def user_gets_reminders(user)
      user.preferences[:notification_config][:matrix][:reminder_reached][:criteria] = {
        'owned_by_me' => true, 'owned_by_nobody' => false, 'subscribed' => true, 'no' => true
      }
      user.save!
    end

    before do
      travel_to Time.current.noon

      [user, other_user].each { user_gets_reminders(it) }

      allow(instance).to receive(:send_to_single_recipient_online)
    end

    context 'with existing locks' do
      before do
        run(ticket, user, 'reminder_reached')
      end

      it 'notification not resent on same day' do
        instance.perform

        expect(instance).not_to have_received(:send_to_single_recipient_online)
      end

      it 'notification is resent on same day if ticket pending time changes' do
        ticket.update!(pending_time: 1.hour.from_now)

        instance.perform

        expect(instance).to have_received(:send_to_single_recipient_online).twice
      end

      context 'when next day' do
        before { travel 1.day }

        it 'notification is resent on next day' do
          instance.perform

          expect(instance).to have_received(:send_to_single_recipient_online).twice
        end

        it 'notification lock is gone next day' do
          expect { run(ticket, other_user, 'reminder_reached') }.to change(Ticket::DailyEventLock, :count).by(2)
        end
      end

      context 'with an additional user' do
        let(:new_user) { create(:agent, groups: [group]) }

        before do
          user_gets_reminders(new_user)
          Rails.cache.clear # clears cache because notification preferences are cached
        end

        it 'notification is sent to new user on same day' do
          instance.perform

          expect(instance).to have_received(:send_to_single_recipient_online).once
        end
      end
    end

    it 'one of notification locks are present when one user fails', aggregate_failures: true do
      call_count = 0
      allow(instance).to receive(:send_to_single_recipient_online) do
        raise StandardError if call_count.positive?

        call_count += 1
      end

      expect do
        expect { instance.perform }.to raise_error(StandardError)
      end.to change(Ticket::DailyEventLock, :count).by(1)
    end
  end

  it_behaves_like 'ChecksHumanChanges'

  describe 'agent notifications across the ticket create/update lifecycle', performs_jobs: true do
    let(:group) do
      Group.create_or_update(
        name:          'TicketNotificationTest',
        updated_by_id: 1,
        created_by_id: 1
      )
    end
    let(:groups) { Group.where(name: 'TicketNotificationTest') }
    let(:agent1) do
      User.create_or_update(
        login:         'ticket-notification-agent1@example.com',
        firstname:     'Notification',
        lastname:      'Agent1',
        email:         'ticket-notification-agent1@example.com',
        password:      'agentpw',
        out_of_office: false,
        active:        true,
        roles:         Role.where(name: 'Agent'),
        groups:        groups,
        preferences:   {
          locale: 'de-de',
        },
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:agent2) do
      User.create_or_update(
        login:         'ticket-notification-agent2@example.com',
        firstname:     'Notification',
        lastname:      'Agent2',
        email:         'ticket-notification-agent2@example.com',
        password:      'agentpw',
        out_of_office: false,
        active:        true,
        roles:         Role.where(name: 'Agent'),
        groups:        groups,
        preferences:   {
          locale:   'en-us',
          timezone: 'America/St_Lucia',
        },
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:agent3) do
      User.create_or_update(
        login:         'ticket-notification-agent3@example.com',
        firstname:     'Notification',
        lastname:      'Agent3',
        email:         'ticket-notification-agent3@example.com',
        password:      'agentpw',
        out_of_office: false,
        active:        true,
        roles:         Role.where(name: 'Agent'),
        groups:        groups,
        preferences:   {
          locale: 'de-de',
        },
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:agent4) do
      User.create_or_update(
        login:         'ticket-notification-agent4@example.com',
        firstname:     'Notification',
        lastname:      'Agent4',
        email:         'ticket-notification-agent4@example.com',
        password:      'agentpw',
        out_of_office: false,
        active:        true,
        roles:         Role.where(name: 'Agent'),
        groups:        groups,
        preferences:   {
          locale: 'de-de',
        },
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:customer) do
      User.create_or_update(
        login:         'ticket-notification-customer@example.com',
        firstname:     'Notification',
        lastname:      'Customer',
        email:         'ticket-notification-customer@example.com',
        password:      'agentpw',
        active:        true,
        roles:         Role.where(name: 'Customer'),
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    before do
      Setting.set('timezone_default', 'Europe/Berlin')
      Trigger.create_or_update(
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
            # rubocop:disable Lint/InterpolationCheck
            'body'      => '<p>Your request (Ticket##{ticket.number}) has been received and will be reviewed by our support staff.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})',
            # rubocop:enable Lint/InterpolationCheck
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      group
      Group.create_if_not_exists(
        name:          'WithoutAccess',
        note:          'Test for notification check.',
        updated_by_id: 1,
        created_by_id: 1
      )

      agent1
      agent2
      agent3
      agent4
      customer
    end

    it 'notifies all group agents for postmaster-created tickets, but not the creating agent for application-server-created tickets', :aggregate_failures do
      ApplicationHandleInfo.use('scheduler.postmaster') do
        ticket1 = Ticket.create!(
          title:         'some notification test 1',
          group:         group,
          customer:      customer,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: agent1.id,
          created_by_id: agent1.id,
        )
        Ticket::Article.create!(
          ticket_id:     ticket1.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.where(name: 'Customer').first,
          type:          Ticket::Article::Type.where(name: 'email').first,
          updated_by_id: agent1.id,
          created_by_id: agent1.id,
        )
        expect(ticket1).to be_truthy

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent1, 'email')).to eq(1)
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent2, 'email')).to eq(1)
      end

      ApplicationHandleInfo.use('application_server') do
        ticket2 = Ticket.create!(
          title:         'some notification test 2',
          group:         group,
          customer:      customer,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: agent1.id,
          created_by_id: agent1.id,
        )
        Ticket::Article.create!(
          ticket_id:     ticket2.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.where(name: 'Customer').first,
          type:          Ticket::Article::Type.where(name: 'email').first,
          updated_by_id: agent1.id,
          created_by_id: agent1.id,
        )
        expect(ticket2).to be_truthy

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket2, agent1, 'email')).to eq(0)
        expect(NotificationFactory::Mailer.already_sent?(ticket2, agent2, 'email')).to eq(1)
      end
    end

    it 'sends notifications based on ticket ownership, group membership and article visibility', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      ApplicationHandleInfo.use('application_server') do
        ticket1 = Ticket.create!(
          title:         'some notification test 3',
          group:         group,
          customer:      customer,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )
        Ticket::Article.create!(
          ticket_id:     ticket1.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.where(name: 'Customer').first,
          type:          Ticket::Article::Type.where(name: 'email').first,
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )
        expect(ticket1).to be_truthy

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent1, 'email')).to eq(1)
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent2, 'email')).to eq(1)

        # update ticket attributes
        ticket1.title    = "#{ticket1.title} - #2"
        ticket1.priority = Ticket::Priority.lookup(name: '3 high')
        ticket1.save!

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent1, 'email')).to eq(2)
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent2, 'email')).to eq(2)

        # add article to ticket
        Ticket::Article.create!(
          ticket_id:     ticket1.id,
          from:          'some person',
          subject:       'some note',
          body:          'some message',
          internal:      true,
          sender:        Ticket::Article::Sender.where(name: 'Agent').first,
          type:          Ticket::Article::Type.where(name: 'note').first,
          updated_by_id: agent1.id,
          created_by_id: agent1.id,
        )

        perform_enqueued_jobs commit_transaction: true

        # verify notifications not to agent1 but to agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent1, 'email')).to eq(2)
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent2, 'email')).to eq(3)

        # update ticket by agent1
        ticket1.owner_id      = agent1.id
        ticket1.updated_by_id = agent1.id
        ticket1.save!
        Ticket::Article.create!(
          ticket_id:     ticket1.id,
          from:          'some person',
          subject:       'some note',
          body:          'some message',
          internal:      true,
          sender:        Ticket::Article::Sender.where(name: 'Agent').first,
          type:          Ticket::Article::Type.where(name: 'note').first,
          updated_by_id: agent1.id,
          created_by_id: agent1.id,
        )

        perform_enqueued_jobs commit_transaction: true

        # verify notifications not to agent1 but to agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent1, 'email')).to eq(2)
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent2, 'email')).to eq(3)

        # create ticket with agent1 as owner
        ticket2 = Ticket.create!(
          title:         'some notification test 4',
          group:         group,
          customer_id:   2,
          owner_id:      agent1.id,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: agent1.id,
          created_by_id: agent1.id,
        )
        Ticket::Article.create!(
          ticket_id:     ticket2.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.where(name: 'Agent').first,
          type:          Ticket::Article::Type.where(name: 'phone').first,
          updated_by_id: agent1.id,
          created_by_id: agent1.id,
        )

        perform_enqueued_jobs commit_transaction: true
        expect(ticket2).to be_truthy

        # verify notifications to no one
        expect(NotificationFactory::Mailer.already_sent?(ticket2, agent1, 'email')).to eq(0)
        expect(NotificationFactory::Mailer.already_sent?(ticket2, agent2, 'email')).to eq(0)

        # update ticket
        ticket2.title         = "#{ticket2.title} - #2"
        ticket2.updated_by_id = agent1.id
        ticket2.priority      = Ticket::Priority.lookup(name: '3 high')
        ticket2.save!

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to none
        expect(NotificationFactory::Mailer.already_sent?(ticket2, agent1, 'email')).to eq(0)
        expect(NotificationFactory::Mailer.already_sent?(ticket2, agent2, 'email')).to eq(0)

        # update ticket
        ticket2.title         = "#{ticket2.title} - #3"
        ticket2.updated_by_id = agent2.id
        ticket2.priority      = Ticket::Priority.lookup(name: '2 normal')
        ticket2.save!

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 and not to agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket2, agent1, 'email')).to eq(1)
        expect(NotificationFactory::Mailer.already_sent?(ticket2, agent2, 'email')).to eq(0)

        # create ticket with agent2 as creator and agent1 as owner
        ticket3 = Ticket.create!(
          title:         'some notification test 5',
          group:         group,
          customer_id:   2,
          owner_id:      agent1.id,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: agent2.id,
          created_by_id: agent2.id,
        )
        article_inbound = Ticket::Article.create!(
          ticket_id:     ticket3.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.where(name: 'Agent').first,
          type:          Ticket::Article::Type.where(name: 'phone').first,
          updated_by_id: agent2.id,
          created_by_id: agent2.id,
        )

        perform_enqueued_jobs commit_transaction: true
        expect(ticket3).to be_truthy

        # verify notifications to agent1 and not to agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket3, agent1, 'email')).to eq(1)
        expect(NotificationFactory::Mailer.already_sent?(ticket3, agent2, 'email')).to eq(0)

        # update ticket
        ticket3.title         = "#{ticket3.title} - #2"
        ticket3.updated_by_id = agent1.id
        ticket3.priority      = Ticket::Priority.lookup(name: '3 high')
        ticket3.save!

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to no one
        expect(NotificationFactory::Mailer.already_sent?(ticket3, agent1, 'email')).to eq(1)
        expect(NotificationFactory::Mailer.already_sent?(ticket3, agent2, 'email')).to eq(0)

        # update ticket
        ticket3.title         = "#{ticket3.title} - #3"
        ticket3.updated_by_id = agent2.id
        ticket3.priority      = Ticket::Priority.lookup(name: '2 normal')
        ticket3.save!

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 and not to agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket3, agent1, 'email')).to eq(2)
        expect(NotificationFactory::Mailer.already_sent?(ticket3, agent2, 'email')).to eq(0)

        # update article / no notification should be sent
        article_inbound.internal = true
        article_inbound.save!

        perform_enqueued_jobs commit_transaction: true

        # verify notifications not to agent1 and not to agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket3, agent1, 'email')).to eq(2)
        expect(NotificationFactory::Mailer.already_sent?(ticket3, agent2, 'email')).to eq(0)

        expect(ticket1.destroy).to be_truthy
        expect(ticket2.destroy).to be_truthy
        expect(ticket3.destroy).to be_truthy
      end
    end

    it 'sends no notifications when disable_notification is passed to the dispatcher', :aggregate_failures do
      ticket1 = Ticket.create!(
        title:         'some notification test 1 - no notification',
        group:         group,
        customer:      customer,
        state:         Ticket::State.lookup(name: 'new'),
        priority:      Ticket::Priority.lookup(name: '2 normal'),
        updated_by_id: customer.id,
        created_by_id: customer.id,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          'some message',
        internal:      false,
        sender:        Ticket::Article::Sender.where(name: 'Customer').first,
        type:          Ticket::Article::Type.where(name: 'email').first,
        updated_by_id: customer.id,
        created_by_id: customer.id,
      )
      expect(ticket1).to be_truthy

      TransactionDispatcher.commit(disable_notification: true)
      perform_enqueued_jobs

      # verify notifications to agent1 + agent2
      expect(NotificationFactory::Mailer.already_sent?(ticket1, agent1, 'email')).to eq(0)
      expect(NotificationFactory::Mailer.already_sent?(ticket1, agent2, 'email')).to eq(0)
    end

    it 'respects each agent\'s notification_config matrix criteria, group scoping and channels', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      ApplicationHandleInfo.use('scheduler.postmaster') do
        agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
        agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
        agent1.preferences['notification_config']['matrix']['create']['criteria']['no'] = false
        agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
        agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
        agent1.preferences['notification_config']['matrix']['update']['criteria']['no'] = false
        agent1.save!

        agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = false
        agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
        agent2.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
        agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = false
        agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
        agent2.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
        agent2.save!

        # create ticket in group
        ticket1 = Ticket.create!(
          title:         'some notification test - z preferences tests 1',
          group:         group,
          customer:      customer,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )
        Ticket::Article.create!(
          ticket_id:     ticket1.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.where(name: 'Customer').first,
          type:          Ticket::Article::Type.where(name: 'email').first,
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent1, 'email')).to eq(0)
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent2, 'email')).to eq(1)

        # update ticket attributes
        ticket1.title    = "#{ticket1.title} - #2"
        ticket1.priority = Ticket::Priority.lookup(name: '3 high')
        ticket1.save!

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent1, 'email')).to eq(0)
        expect(NotificationFactory::Mailer.already_sent?(ticket1, agent2, 'email')).to eq(2)

        # create ticket in group
        ticket2 = Ticket.create!(
          title:         'some notification test - z preferences tests 2',
          group:         group,
          customer:      customer,
          owner:         agent1,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )
        Ticket::Article.create!(
          ticket_id:     ticket2.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.where(name: 'Customer').first,
          type:          Ticket::Article::Type.where(name: 'email').first,
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket2, agent1, 'email')).to eq(1)
        expect(NotificationFactory::Mailer.already_sent?(ticket2, agent2, 'email')).to eq(1)

        # update ticket attributes
        ticket2.title    = "#{ticket2.title} - #2"
        ticket2.priority = Ticket::Priority.lookup(name: '3 high')
        ticket2.save!

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket2, agent1, 'email')).to eq(2)
        expect(NotificationFactory::Mailer.already_sent?(ticket2, agent2, 'email')).to eq(2)

        # create ticket in group
        ticket3 = Ticket.create!(
          title:         'some notification test - z preferences tests 3',
          group:         group,
          customer:      customer,
          owner:         agent2,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )
        Ticket::Article.create!(
          ticket_id:     ticket3.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.where(name: 'Customer').first,
          type:          Ticket::Article::Type.where(name: 'email').first,
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket3, agent1, 'email')).to eq(0)
        expect(NotificationFactory::Mailer.already_sent?(ticket3, agent2, 'email')).to eq(1)

        # update ticket attributes
        ticket3.title    = "#{ticket3.title} - #2"
        ticket3.priority = Ticket::Priority.lookup(name: '3 high')
        ticket3.save!

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket3, agent1, 'email')).to eq(0)
        expect(NotificationFactory::Mailer.already_sent?(ticket3, agent2, 'email')).to eq(2)

        agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
        agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
        agent1.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
        agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
        agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
        agent1.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
        agent1.preferences['notification_config']['group_ids'] = [group.id.to_s]
        agent1.save!

        agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = false
        agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
        agent2.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
        agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = false
        agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
        agent2.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
        agent1.preferences['notification_config']['group_ids'] = ['-']
        agent2.save!

        travel 1.minute # to skip lookup cache in Transaction::Notification
        if Rails.application.config.cache_store.first.eql? :mem_cache_store
          # External memcached does not support time travel, so clear the cache to avoid an outdated match.
          Rails.cache.clear
        end

        # create ticket in group
        ticket4 = Ticket.create!(
          title:         'some notification test - z preferences tests 4',
          group:         group,
          customer:      customer,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )
        Ticket::Article.create!(
          ticket_id:     ticket4.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.where(name: 'Customer').first,
          type:          Ticket::Article::Type.where(name: 'email').first,
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket4, agent1, 'email')).to eq(1)
        expect(NotificationFactory::Mailer.already_sent?(ticket4, agent2, 'email')).to eq(1)

        # update ticket attributes
        ticket4.title    = "#{ticket4.title} - #2"
        ticket4.priority = Ticket::Priority.lookup(name: '3 high')
        ticket4.save!

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket4, agent1, 'email')).to eq(2)
        expect(NotificationFactory::Mailer.already_sent?(ticket4, agent2, 'email')).to eq(2)

        agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
        agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
        agent1.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
        agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
        agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
        agent1.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
        agent1.preferences['notification_config']['group_ids'] = [group.id.to_s]
        agent1.save!

        agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = false
        agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
        agent2.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
        agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = false
        agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
        agent2.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
        agent2.preferences['notification_config']['group_ids'] = [99]
        agent2.save!

        travel 1.minute # to skip lookup cache in Transaction::Notification
        if Rails.application.config.cache_store.first.eql? :mem_cache_store
          # External memcached does not support time travel, so clear the cache to avoid an outdated match.
          Rails.cache.clear
        end

        # create ticket in group
        ticket5 = Ticket.create!(
          title:         'some notification test - z preferences tests 5',
          group:         group,
          customer:      customer,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )
        Ticket::Article.create!(
          ticket_id:     ticket5.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.where(name: 'Customer').first,
          type:          Ticket::Article::Type.where(name: 'email').first,
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket5, agent1, 'email')).to eq(1)
        expect(NotificationFactory::Mailer.already_sent?(ticket5, agent2, 'email')).to eq(0)

        # update ticket attributes
        ticket5.title    = "#{ticket5.title} - #2"
        ticket5.priority = Ticket::Priority.lookup(name: '3 high')
        ticket5.save!

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket5, agent1, 'email')).to eq(2)
        expect(NotificationFactory::Mailer.already_sent?(ticket5, agent2, 'email')).to eq(0)

        agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
        agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
        agent1.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
        agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
        agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
        agent1.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
        agent1.preferences['notification_config']['group_ids'] = [999]
        agent1.save!

        agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
        agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
        agent2.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
        agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
        agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
        agent2.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
        agent2.preferences['notification_config']['group_ids'] = [999]
        agent2.save!

        travel 1.minute # to skip lookup cache in Transaction::Notification
        if Rails.application.config.cache_store.first.eql? :mem_cache_store
          # External memcached does not support time travel, so clear the cache to avoid an outdated match.
          Rails.cache.clear
        end

        # create ticket in group
        ticket6 = Ticket.create!(
          title:         'some notification test - z preferences tests 6',
          group:         group,
          customer:      customer,
          owner:         agent1,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )
        Ticket::Article.create!(
          ticket_id:     ticket6.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.where(name: 'Customer').first,
          type:          Ticket::Article::Type.where(name: 'email').first,
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket6, agent1, 'email')).to eq(1)
        expect(NotificationFactory::Mailer.already_sent?(ticket6, agent1, 'online')).to eq(1)
        expect(NotificationFactory::Mailer.already_sent?(ticket6, agent2, 'email')).to eq(0)
        expect(NotificationFactory::Mailer.already_sent?(ticket6, agent2, 'online')).to eq(0)

        # update ticket attributes
        ticket6.title    = "#{ticket6.title} - #2"
        ticket6.priority = Ticket::Priority.lookup(name: '3 high')
        ticket6.save!

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket6, agent1, 'email')).to eq(2)
        expect(NotificationFactory::Mailer.already_sent?(ticket6, agent1, 'online')).to eq(2)
        expect(NotificationFactory::Mailer.already_sent?(ticket6, agent2, 'email')).to eq(0)
        expect(NotificationFactory::Mailer.already_sent?(ticket6, agent2, 'online')).to eq(0)

        agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
        agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
        agent1.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
        agent1.preferences['notification_config']['matrix']['create']['channel']['email'] = false
        agent1.preferences['notification_config']['matrix']['create']['channel']['online'] = true
        agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
        agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
        agent1.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
        agent1.preferences['notification_config']['matrix']['update']['channel']['email'] = false
        agent1.preferences['notification_config']['matrix']['update']['channel']['online'] = true
        agent1.preferences['notification_config']['group_ids'] = [999]
        agent1.save!

        agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
        agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
        agent2.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
        agent2.preferences['notification_config']['matrix']['create']['channel']['email'] = false
        agent2.preferences['notification_config']['matrix']['create']['channel']['online'] = true
        agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
        agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
        agent2.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
        agent2.preferences['notification_config']['matrix']['update']['channel']['email'] = false
        agent2.preferences['notification_config']['matrix']['update']['channel']['online'] = true
        agent2.preferences['notification_config']['group_ids'] = [999]
        agent2.save!

        travel 1.minute # to skip lookup cache in Transaction::Notification
        if Rails.application.config.cache_store.first.eql? :mem_cache_store
          # External memcached does not support time travel, so clear the cache to avoid an outdated match.
          Rails.cache.clear
        end

        # create ticket in group
        ticket7 = Ticket.create!(
          title:         'some notification test - z preferences tests 7',
          group:         group,
          customer:      customer,
          owner:         agent1,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )
        Ticket::Article.create!(
          ticket_id:     ticket7.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message',
          internal:      false,
          sender:        Ticket::Article::Sender.where(name: 'Customer').first,
          type:          Ticket::Article::Type.where(name: 'email').first,
          updated_by_id: customer.id,
          created_by_id: customer.id,
        )

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket7, agent1, 'email')).to eq(0)
        expect(NotificationFactory::Mailer.already_sent?(ticket7, agent1, 'online')).to eq(1)
        expect(NotificationFactory::Mailer.already_sent?(ticket7, agent2, 'email')).to eq(0)
        expect(NotificationFactory::Mailer.already_sent?(ticket7, agent2, 'online')).to eq(0)

        # update ticket attributes
        ticket7.title    = "#{ticket7.title} - #2"
        ticket7.priority = Ticket::Priority.lookup(name: '3 high')
        ticket7.save!

        perform_enqueued_jobs commit_transaction: true

        # verify notifications to agent1 + agent2
        expect(NotificationFactory::Mailer.already_sent?(ticket7, agent1, 'email')).to eq(0)
        expect(NotificationFactory::Mailer.already_sent?(ticket7, agent1, 'online')).to eq(2)
        expect(NotificationFactory::Mailer.already_sent?(ticket7, agent2, 'email')).to eq(0)
        expect(NotificationFactory::Mailer.already_sent?(ticket7, agent2, 'online')).to eq(0)
      end
    ensure
      travel_back
    end

    it 'merges buffered ticket changes into a single uniq change set per attribute', :aggregate_failures do
      # create ticket in group
      ticket1 = Ticket.create!(
        title:         'some notification event test 1',
        group:         group,
        customer:      customer,
        state:         Ticket::State.lookup(name: 'new'),
        priority:      Ticket::Priority.lookup(name: '2 normal'),
        updated_by_id: customer.id,
        created_by_id: customer.id,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          'some message',
        internal:      false,
        sender:        Ticket::Article::Sender.where(name: 'Customer').first,
        type:          Ticket::Article::Type.where(name: 'email').first,
        updated_by_id: customer.id,
        created_by_id: customer.id,
      )
      expect(ticket1).to be_truthy

      # execute object transaction
      TransactionDispatcher.commit

      # update ticket attributes
      ticket1.title    = "#{ticket1.title} - #2"
      ticket1.priority = Ticket::Priority.lookup(name: '3 high')
      ticket1.save!

      list         = EventBuffer.list('transaction')
      list_objects = TransactionDispatcher.get_uniq_changes(list)

      expect(list_objects['Ticket'][ticket1.id][:changes]['title'][0]).to eq('some notification event test 1')
      expect(list_objects['Ticket'][ticket1.id][:changes]['title'][1]).to eq('some notification event test 1 - #2')
      expect(list_objects['Ticket'][ticket1.id][:changes]['priority']).to be_falsey
      expect(list_objects['Ticket'][ticket1.id][:changes]['priority_id'][0]).to eq(2)
      expect(list_objects['Ticket'][ticket1.id][:changes]['priority_id'][1]).to eq(3)

      # update ticket attributes
      ticket1.title    = "#{ticket1.title} - #3"
      ticket1.priority = Ticket::Priority.lookup(name: '1 low')
      ticket1.save!

      list         = EventBuffer.list('transaction')
      list_objects = TransactionDispatcher.get_uniq_changes(list)

      expect(list_objects['Ticket'][ticket1.id][:changes]['title'][0]).to eq('some notification event test 1')
      expect(list_objects['Ticket'][ticket1.id][:changes]['title'][1]).to eq('some notification event test 1 - #2 - #3')
      expect(list_objects['Ticket'][ticket1.id][:changes]['priority']).to be_falsey
      expect(list_objects['Ticket'][ticket1.id][:changes]['priority_id'][0]).to eq(2)
      expect(list_objects['Ticket'][ticket1.id][:changes]['priority_id'][1]).to eq(1)
    end

    it 'reroutes email notifications to an out-of-office agent\'s replacement', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      # create ticket in group
      ticket1 = Ticket.create!(
        title:         'some notification test out of office',
        group:         group,
        customer:      customer,
        owner_id:      agent2.id,
        updated_by_id: customer.id,
        created_by_id: customer.id,
      )
      Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          'some message',
        internal:      false,
        sender:        Ticket::Article::Sender.where(name: 'Customer').first,
        type:          Ticket::Article::Type.where(name: 'email').first,
        updated_by_id: customer.id,
        created_by_id: customer.id,
      )
      expect(ticket1).to be_truthy

      perform_enqueued_jobs commit_transaction: true

      # verify notifications to agent1 + agent2
      expect(NotificationFactory::Mailer.already_sent?(ticket1, agent1, 'email')).to eq(0)
      expect(NotificationFactory::Mailer.already_sent?(ticket1, agent2, 'email')).to eq(1)
      expect(NotificationFactory::Mailer.already_sent?(ticket1, agent3, 'email')).to eq(0)
      expect(NotificationFactory::Mailer.already_sent?(ticket1, agent4, 'email')).to eq(0)

      agent2.out_of_office = true
      agent2.preferences[:out_of_office_text] = 'at the doctor'
      agent2.out_of_office_replacement_id = agent3.id
      agent2.out_of_office_start_at = Time.zone.today - 2.days
      agent2.out_of_office_end_at = Time.zone.today + 2.days
      agent2.save!

      # create ticket in group
      ticket2 = Ticket.create!(
        title:         'some notification test out of office',
        group:         group,
        customer:      customer,
        owner_id:      agent2.id,
        updated_by_id: customer.id,
        created_by_id: customer.id,
      )
      Ticket::Article.create!(
        ticket_id:     ticket2.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          'some message',
        internal:      false,
        sender:        Ticket::Article::Sender.where(name: 'Customer').first,
        type:          Ticket::Article::Type.where(name: 'email').first,
        updated_by_id: customer.id,
        created_by_id: customer.id,
      )
      expect(ticket2).to be_truthy

      perform_enqueued_jobs commit_transaction: true

      # verify notifications to agent1 + agent2
      expect(NotificationFactory::Mailer.already_sent?(ticket2, agent1, 'email')).to eq(0)
      expect(NotificationFactory::Mailer.already_sent?(ticket2, agent2, 'email')).to eq(1)
      expect(NotificationFactory::Mailer.already_sent?(ticket2, agent3, 'email')).to eq(1)
      expect(NotificationFactory::Mailer.already_sent?(ticket2, agent4, 'email')).to eq(0)

      # update ticket attributes
      ticket2.title    = "#{ticket2.title} - #2"
      ticket2.priority = Ticket::Priority.lookup(name: '3 high')
      ticket2.save!

      perform_enqueued_jobs commit_transaction: true

      # verify notifications to agent1 + agent2
      expect(NotificationFactory::Mailer.already_sent?(ticket2, agent1, 'email')).to eq(0)
      expect(NotificationFactory::Mailer.already_sent?(ticket2, agent2, 'email')).to eq(2)
      expect(NotificationFactory::Mailer.already_sent?(ticket2, agent3, 'email')).to eq(2)
      expect(NotificationFactory::Mailer.already_sent?(ticket2, agent4, 'email')).to eq(0)

      agent3.out_of_office = true
      agent3.preferences[:out_of_office_text] = 'at the doctor'
      agent3.out_of_office_replacement_id = agent4.id
      agent3.out_of_office_start_at = Time.zone.today - 2.days
      agent3.out_of_office_end_at = Time.zone.today + 2.days
      agent3.save!

      # update ticket attributes
      ticket2.title    = "#{ticket2.title} - #3"
      ticket2.priority = Ticket::Priority.lookup(name: '3 high')
      ticket2.save!

      perform_enqueued_jobs commit_transaction: true

      # verify notifications to agent1 + agent2
      expect(NotificationFactory::Mailer.already_sent?(ticket2, agent1, 'email')).to eq(0)
      expect(NotificationFactory::Mailer.already_sent?(ticket2, agent2, 'email')).to eq(3)
      expect(NotificationFactory::Mailer.already_sent?(ticket2, agent3, 'email')).to eq(2)
      expect(NotificationFactory::Mailer.already_sent?(ticket2, agent4, 'email')).to eq(1)
    end

    it 'renders localized notification templates with human-readable changes', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      # create ticket in group
      ticket1 = Ticket.create!(
        title:         'some notification template test 1 Bobs\'s resumé',
        group:         group,
        customer:      customer,
        state:         Ticket::State.lookup(name: 'new'),
        priority:      Ticket::Priority.lookup(name: '2 normal'),
        updated_by_id: customer.id,
        created_by_id: customer.id,
      )
      article = Ticket::Article.create!(
        ticket_id:     ticket1.id,
        from:          'some_sender@example.com',
        to:            'some_recipient@example.com',
        subject:       'some subject',
        message_id:    'some@id',
        body:          "some message\nnewline1 abc\nnewline2",
        internal:      false,
        sender:        Ticket::Article::Sender.where(name: 'Customer').first,
        type:          Ticket::Article::Type.where(name: 'email').first,
        updated_by_id: customer.id,
        created_by_id: customer.id,
      )
      expect(ticket1).to be_truthy

      last_changes = {
        'priority_id'  => [1, 2],
        'pending_time' => [nil, Time.zone.parse('2015-01-11 23:33:47 UTC')],
      }

      bg = described_class.new(
        ticket_id:  ticket1.id,
        article_id: article.id,
        type:       'update',
        changes:    last_changes,
        user_id:    ticket1.updated_by_id,
      )

      # check changed attributes
      human_changes = bg.human_changes(last_changes, ticket1, agent2)
      expect(human_changes['Priority']).to be_truthy
      expect(human_changes['Pending till']).to be_truthy
      expect(human_changes['Priority'][0]).to eq('1 low')
      expect(human_changes['Priority'][1]).to eq('2 normal')
      expect(human_changes['Pending till'][0].to_s).to eq('')
      expect(human_changes['Pending till'][1].to_s).to eq('2015-01-11 23:33:47 UTC')
      expect(human_changes['priority_id']).to be_falsey
      expect(human_changes['pending_time']).to be_falsey
      expect(human_changes['pending_till']).to be_falsey

      # en notification
      result = NotificationFactory::Mailer.template(
        locale:   agent2.preferences[:locale],
        timezone: agent2.preferences[:timezone],
        template: 'ticket_update',
        objects:  {
          ticket:    ticket1,
          article:   article,
          recipient: agent2,
          changes:   human_changes,
        },
      )
      expect(result[:subject]).to include("Bobs's resumé")
      expect(result[:body]).to include('Priority')
      expect(result[:body]).to include('1 low')
      expect(result[:body]).to include('2 normal')
      expect(result[:body]).to include('Pending till')
      expect(result[:body]).to include('01/11/2015  7:33 pm (America/St_Lucia)')
      expect(result[:body]).to include('update')
      expect(result[:body]).not_to include('pending_till')
      expect(result[:body]).not_to include('i18n')

      human_changes = bg.human_changes(last_changes, ticket1, agent1)
      expect(human_changes['Priority']).to be_truthy
      expect(human_changes['Pending till']).to be_truthy
      expect(human_changes['Priority'][0]).to eq('1 niedrig')
      expect(human_changes['Priority'][1]).to eq('2 normal')
      expect(human_changes['Pending till'][0].to_s).to eq('')
      expect(human_changes['Pending till'][1].to_s).to eq('2015-01-11 23:33:47 UTC')
      expect(human_changes['priority_id']).to be_falsey
      expect(human_changes['pending_time']).to be_falsey
      expect(human_changes['pending_till']).to be_falsey

      # de & Europe/Berlin notification
      result = NotificationFactory::Mailer.template(
        locale:   agent1.preferences[:locale],
        timezone: agent1.preferences[:timezone],
        template: 'ticket_update',
        objects:  {
          ticket:    ticket1,
          article:   article,
          recipient: agent1,
          changes:   human_changes,
        },
      )

      expect(result[:subject]).to include("Bobs's resumé")
      expect(result[:body]).to include('Priorität')
      expect(result[:body]).to include('1 niedrig')
      expect(result[:body]).to include('2 normal')
      expect(result[:body]).to include('Warten')
      expect(result[:body]).to include('12.01.2015 00:33 (Europe/Berlin)')
      expect(result[:body]).to include('aktualis')
      expect(result[:body]).not_to include('pending_till')
      expect(result[:body]).not_to include('i18n')

      last_changes = {
        title:       ['some notification template test old 1', 'some notification template test 1 #2'],
        priority_id: [2, 3],
      }

      bg = described_class.new(
        ticket_id:  ticket1.id,
        article_id: article.id,
        type:       'update',
        changes:    last_changes,
        user_id:    customer.id,
      )

      # check changed attributes
      human_changes = bg.human_changes(last_changes, ticket1, agent1)
      expect(human_changes['Title']).to be_truthy
      expect(human_changes['Priority']).to be_truthy
      expect(human_changes['Priority'][0]).to eq('2 normal')
      expect(human_changes['Priority'][1]).to eq('3 hoch')
      expect(human_changes['Title'][0]).to eq('some notification template test old 1')
      expect(human_changes['Title'][1]).to eq('some notification template test 1 #2')
      expect(human_changes['priority_id']).to be_falsey
      expect(human_changes['pending_time']).to be_falsey
      expect(human_changes['pending_till']).to be_falsey

      # de notification
      result = NotificationFactory::Mailer.template(
        locale:   agent1.preferences[:locale],
        timezone: agent1.preferences[:timezone],
        template: 'ticket_update',
        objects:  {
          ticket:    ticket1,
          article:   article,
          recipient: agent1,
          changes:   human_changes,
        }
      )

      expect(result[:subject]).to include("Bobs's resumé")
      expect(result[:body]).to include('Titel')
      expect(result[:body]).not_to include('Title')
      expect(result[:body]).to include('some notification template test old 1')
      expect(result[:body]).to include('some notification template test 1 #2')
      expect(result[:body]).to include('Priorität')
      expect(result[:body]).not_to include('Priority')
      expect(result[:body]).to include('3 hoch')
      expect(result[:body]).to include('2 normal')
      expect(result[:body]).to include('aktualisier')

      human_changes = bg.human_changes(last_changes, ticket1, agent2)

      # en notification
      result = NotificationFactory::Mailer.template(
        locale:   agent2.preferences[:locale],
        timezone: agent2.preferences[:timezone],
        template: 'ticket_update',
        objects:  {
          ticket:    ticket1,
          article:   article,
          recipient: agent2,
          changes:   human_changes,
        }
      )

      expect(result[:subject]).to include("Bobs's resumé")
      expect(result[:body]).to include('Title')
      expect(result[:body]).to include('some notification template test old 1')
      expect(result[:body]).to include('some notification template test 1 #2')
      expect(result[:body]).to include('Priority')
      expect(result[:body]).to include('3 high')
      expect(result[:body]).to include('2 normal')
      expect(result[:body]).not_to include('Pending till')
      expect(result[:body]).not_to include('2015-01-11 23:33:47 UTC')
      expect(result[:body]).to include('update')
      expect(result[:body]).not_to include('pending_till')
      expect(result[:body]).not_to include('i18n')

      # en notification
      ticket1.escalation_at = Time.zone.parse('2019-04-01T10:00:00Z')
      result = NotificationFactory::Mailer.template(
        locale:   agent2.preferences[:locale],
        timezone: agent2.preferences[:timezone],
        template: 'ticket_escalation',
        objects:  {
          ticket:    ticket1,
          article:   article,
          recipient: agent2,
        }
      )

      expect(result[:subject]).to include('Escalated ticket (some notification template test 1 Bobs\'s resumé')
      expect(result[:body]).to include('escalated since "04/01/2019  6:00 am (America/St_Lucia)"!')
    end
  end

  def run(ticket, user, type)
    build(ticket, user, type).perform
  end

  def build(ticket, user, type = 'reminder_reached')
    described_class.new(
      object:           ticket.class.name,
      type:             type,
      object_id:        ticket.id,
      interface_handle: 'scheduler',
      changes:          nil,
      created_at:       Time.current,
      user_id:          user.id
    )
  end

  def ooo(instance, user, replacements: Set.new, reasons: [])
    instance.send(:ooo_replacements, user: user, replacements: replacements, ticket: ticket, reasons: reasons)
  end
end
