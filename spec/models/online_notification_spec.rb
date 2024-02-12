# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe OnlineNotification, type: :model do
  subject(:online_notification) { create(:online_notification, o: ticket) }

  let(:ticket) { create(:ticket) }

  it_behaves_like 'ApplicationModel', can_param: { sample_data_attribute: :seen }

  describe '#related_object' do
    it 'returns ticket' do
      expect(online_notification.related_object).to eq ticket
    end
  end

  describe '.add' do
    describe 'validations' do
      describe 'referenced object' do
        it 'raises RuntimeError for invalid object name' do
          expect do
            described_class.add(
              type:          'create',
              object:        'TicketNotExisting',
              o_id:          123,
              seen:          false,
              user_id:       create(:agent).id,
              created_by_id: 1,
              updated_by_id: 1,
              created_at:    10.months.ago,
              updated_at:    10.months.ago,
            )
          end.to raise_error(RuntimeError)
        end

        it 'raises RecordNotFound if object does not exist' do
          expect do
            described_class.add(
              type:          'create',
              object:        'Ticket',
              o_id:          123,
              seen:          false,
              user_id:       create(:agent).id,
              created_by_id: 1,
              updated_by_id: 1,
              created_at:    10.months.ago,
              updated_at:    10.months.ago,
            )
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe '.list' do
    let(:user)           { create(:agent, groups: [group]) }
    let(:another_user)   { create(:agent, groups: [group]) }
    let(:group)          { create(:group) }
    let(:ticket)         { create(:ticket, group: group) }
    let(:another_ticket) { create(:ticket, group: group) }
    let(:notification_1) { create(:online_notification, o: ticket, user: user) }
    let(:notification_2) { create(:online_notification, o: ticket, user: another_user) }
    let(:notification_3) { create(:online_notification, o: another_ticket, user: user) }

    before do
      notification_1 && notification_2 && notification_3
    end

    it 'returns notifications for a given user' do
      expect(described_class.list(user))
        .to contain_exactly(notification_1, notification_3)
    end

    context 'when user looses access to one of the referenced tickets' do
      before do
        another_ticket.update! group: create(:group)
      end

      it 'with ensure_access flag it returns notifications given user has access to' do
        expect(described_class.list(user, access: 'full'))
          .to contain_exactly(notification_1)
      end

      it 'without ensure_access flag it returns all notifications given user has' do
        expect(described_class.list(user, access: 'ignore'))
          .to contain_exactly(notification_1, notification_3)
      end
    end
  end

  describe 'notification creation', performs_jobs: true do
    let(:group)    { create(:group) }
    let(:agent1)   { create(:agent, groups: [group]) }
    let(:agent2)   { create(:agent, groups: [group]) }
    let(:agent3)   { create(:agent) }
    let(:customer) { create(:customer) }
    let(:system)   { User.lookup(login: '-') }

    let(:ticket) do
      create(:ticket,
             group:      group,
             customer:   customer,
             owner:      ticket_owner,
             state_name: state_name,
             updated_by: ticket_author,
             created_by: ticket_author)
    end

    let(:first_article) do
      create(:ticket_article,
             ticket:      ticket,
             type_name:   'phone',
             sender_name: 'Customer',
             from:        'Unit Test <unittest@example.com>',
             body:        'Unit Test 123',
             internal:    false,
             updated_by:  article_author,
             created_by:  article_author)
    end

    def notifications_scope(type_name)
      described_class.where(
        object_lookup_id: ObjectLookup.by_name('Ticket'),
        type_lookup_id:   TypeLookup.by_name(type_name),
        o_id:             ticket.id
      )
    end

    around do |example|
      ApplicationHandleInfo.use('application_server') do
        example.run
      end
    end

    before do
      agent1 && agent2 && agent3 && customer
      first_article

      perform_enqueued_jobs commit_transaction: true
    end

    shared_examples 'destroyable notifications' do
      let(:destroyable_ticket) { ticket }

      it 'removes all notifications when destroying a ticket' do
        destroyable_ticket.destroy

        expect(described_class.list_by_object('Ticket', destroyable_ticket.id))
          .to be_blank
      end
    end

    context 'when closed ticket owner is system' do
      let(:ticket_owner)   { system }
      let(:ticket_author)  { agent1 }
      let(:article_author) { agent1 }
      let(:state_name)     { 'closed' }

      it 'adds already seen create notification for the other agent' do
        expect(notifications_scope('create'))
          .to contain_exactly(
            have_attributes(user: agent2, created_by: agent1, seen: true)
          )
      end

      it_behaves_like 'destroyable notifications'

      context 'when customer updates a closed ticket' do
        before do
          ticket.update!(
            state_id:      Ticket::State.lookup(name: 'open').id,
            priority_id:   Ticket::Priority.lookup(name: '1 low').id,
            created_by_id: customer.id,
            updated_by_id: customer.id,
          )
          perform_enqueued_jobs commit_transaction: true
        end

        it 'adds unseen update notifications for both agents' do
          expect(notifications_scope('update'))
            .to contain_exactly(
              have_attributes(user: agent1, created_by: customer, seen: false),
              have_attributes(user: agent2, created_by: customer, seen: false)
            )
        end

        it_behaves_like 'destroyable notifications'
      end
    end

    context 'when closed ticket owner is agent and started by customer' do
      let(:ticket_owner)   { agent1 }
      let(:ticket_author)  { customer }
      let(:article_author) { customer }
      let(:state_name)     { 'closed' }

      it 'adds unseen create notification for owner agent' do
        expect(notifications_scope('create'))
          .to contain_exactly(
            have_attributes(user: agent1, created_by: customer, seen: false)
          )
      end

      it_behaves_like 'destroyable notifications'

      context 'when customer updates a closed ticket' do
        before do
          ticket.update!(
            state_id:      Ticket::State.lookup(name: 'open').id,
            priority_id:   Ticket::Priority.lookup(name: '1 low').id,
            created_by_id: customer.id,
            updated_by_id: customer.id,
          )
          perform_enqueued_jobs commit_transaction: true
        end

        it 'adds unseen update notifications for owner agent' do
          expect(notifications_scope('update'))
            .to contain_exactly(
              have_attributes(user: agent1, created_by: customer, seen: false),
            )
        end

        it_behaves_like 'destroyable notifications'
      end
    end

    context 'when new ticket owner is system and started by agent' do
      let(:ticket_owner)   { system }
      let(:ticket_author)  { agent1 }
      let(:article_author) { agent1 }
      let(:state_name)     { 'new' }

      it 'adds unseen create notification for another agent' do
        expect(notifications_scope('create'))
          .to contain_exactly(
            have_attributes(user: agent2, created_by: agent1, seen: false)
          )
      end

      it_behaves_like 'destroyable notifications'

      context 'when customer closes ticket' do
        before do
          ticket.update!(
            state_id:      Ticket::State.lookup(name: 'closed').id,
            priority_id:   Ticket::Priority.lookup(name: '1 low').id,
            created_by_id: customer.id,
            updated_by_id: customer.id,
          )
          perform_enqueued_jobs commit_transaction: true
        end

        it 'sends notifications to both agents', :aggregate_failures do
          expect(NotificationFactory::Mailer.already_sent?(ticket, agent1, 'update')).to eq(1)
          expect(NotificationFactory::Mailer.already_sent?(ticket, agent2, 'update')).to eq(1)
        end

        it 'adds seen notification to both agents' do
          expect(notifications_scope('update'))
            .to contain_exactly(
              have_attributes(user: agent1, created_by: customer, seen: true),
              have_attributes(user: agent2, created_by: customer, seen: true),
            )
        end

        it_behaves_like 'destroyable notifications'

        context 'when phone article by customer is added' do
          before do
            create(:ticket_article, :inbound_phone, ticket: ticket, updated_by: customer, created_by: customer)

            perform_enqueued_jobs commit_transaction: true
          end

          it 'sends notifications to both agents', :aggregate_failures do
            expect(NotificationFactory::Mailer.already_sent?(ticket, agent1, 'update')).to eq(2)
            expect(NotificationFactory::Mailer.already_sent?(ticket, agent2, 'update')).to eq(2)
          end

          it 'adds unseen notifications to both agents' do
            expect(notifications_scope('update'))
              .to contain_exactly(
                have_attributes(user: agent1, created_by: customer, seen: true),
                have_attributes(user: agent2, created_by: customer, seen: true),
                have_attributes(user: agent1, created_by: customer, seen: false),
                have_attributes(user: agent2, created_by: customer, seen: false)
              )
          end

          it_behaves_like 'destroyable notifications'
        end
      end
    end

    context 'when new ticket owner is agent and created by customer' do
      let(:ticket_owner)   { agent1 }
      let(:ticket_author)  { customer }
      let(:article_author) { customer }
      let(:state_name)     { 'new' }

      it 'adds notification to owner agent' do
        expect(notifications_scope('create'))
          .to contain_exactly(
            have_attributes(user: agent1, created_by: customer, seen: false)
          )
      end

      it_behaves_like 'destroyable notifications'

      context 'when ticket is updated to open' do
        before do
          ticket.update!(
            state_id:      Ticket::State.lookup(name: 'open').id,
            priority_id:   Ticket::Priority.lookup(name: '1 low').id,
            created_by_id: customer.id,
            updated_by_id: customer.id,
          )
          perform_enqueued_jobs commit_transaction: true
        end

        it 'adds notification to owner agent' do
          expect(notifications_scope('update'))
            .to contain_exactly(
              have_attributes(user: agent1, created_by: customer, seen: false),
            )
        end

        it_behaves_like 'destroyable notifications'
      end
    end

    context 'when new ticket owner is system and created by customer' do
      let(:ticket_owner)   { system }
      let(:ticket_author)  { agent1 }
      let(:article_author) { agent1 }
      let(:state_name)     { 'new' }

      it 'adds unseen notification to another agent' do
        expect(notifications_scope('create'))
          .to contain_exactly(
            have_attributes(user: agent2, created_by: agent1, seen: false)
          )
      end

      it_behaves_like 'destroyable notifications'

      context 'when ticket is updated by customer to open' do
        before do
          ticket.update!(
            state_id:      Ticket::State.lookup(name: 'open').id,
            priority_id:   Ticket::Priority.lookup(name: '1 low').id,
            created_by_id: customer.id,
            updated_by_id: customer.id,
          )
          perform_enqueued_jobs commit_transaction: true
        end

        it 'adds unseen notification to both agents' do
          expect(notifications_scope('update'))
            .to contain_exactly(
              have_attributes(user: agent1, created_by: customer, seen: false),
              have_attributes(user: agent2, created_by: customer, seen: false)
            )
        end

        it_behaves_like 'destroyable notifications'
      end
    end

    context 'when merging tickets' do
      let(:ticket_owner)       { system }
      let(:ticket_author)      { agent1 }
      let(:article_author)     { agent1 }
      let(:state_name)         { 'open' }
      let(:target_ticket)      { create(:ticket, group: group) }

      before do
        ticket && target_ticket

        perform_enqueued_jobs

        ticket.merge_to(
          ticket_id: target_ticket.id,
          user_id:   1,
        )

        perform_enqueued_jobs
      end

      it 'notifications for origin ticket are still available' do
        expect(described_class.list_by_object('Ticket', ticket.id))
          .to be_present
      end

      it 'notifications for target ticket are still available' do
        expect(described_class.list_by_object('Ticket', target_ticket.id))
          .to be_present
      end

      it 'origin ticket has no unseen notifications' do
        expect(described_class.list_by_object('Ticket', ticket.id))
          .not_to exist(seen: false)
      end

      it 'target ticket has new notifications that are not seen notifications' do
        expect(described_class.list_by_object('Ticket', target_ticket.id))
          .to exist(seen: false)
      end

      it_behaves_like 'destroyable notifications'
      it_behaves_like 'destroyable notifications' do
        let(:destroyable_ticket) { target_ticket }
      end
    end
  end

  describe '.cleanup' do
    let(:max_age)      { 1.week }
    let(:own_seen)     { 1.minute }
    let(:auto_seen)    { 10.minutes }
    let(:user)         { create(:agent) }
    let(:notification) { create(:online_notification, user: user, seen: false, created_by: user) }

    before { notification }

    context 'when seen' do
      context 'when seen by user' do
        before do
          travel 10.minutes
          notification.update!(seen: true, updated_by: user)
        end

        it 'stays if it was just seen' do
          described_class.cleanup(max_age.ago, own_seen.ago, auto_seen.ago)
          expect(described_class).to exist(notification.id)
        end

        it 'deleted after own seen time passes' do
          travel own_seen + 1.minute
          described_class.cleanup(max_age.ago, own_seen.ago, auto_seen.ago)
          expect(described_class).not_to exist(notification.id)
        end
      end

      context 'when seen by another user' do
        before do
          travel 10.minutes
          notification.update!(seen: true)
        end

        it 'stays if it was just seen' do
          described_class.cleanup(max_age.ago, own_seen.ago, auto_seen.ago)
          expect(described_class).to exist(notification.id)
        end

        it 'not deleted after own seen time passes' do
          travel own_seen + 1.minute
          described_class.cleanup(max_age.ago, own_seen.ago, auto_seen.ago)
          expect(described_class).to exist(notification.id)
        end

        it 'deleted after auto seen time passes' do
          travel auto_seen + 1.minute
          described_class.cleanup(max_age.ago, own_seen.ago, auto_seen.ago)
          expect(described_class).not_to exist(notification.id)
        end
      end
    end

    context 'when not seen' do
      it 'stays if it is fresh' do
        described_class.cleanup(max_age.ago, own_seen.ago, auto_seen.ago)
        expect(described_class).to exist(notification.id)
      end

      it 'stays after own seen time passes' do
        travel own_seen + 1.minute
        described_class.cleanup(max_age.ago, own_seen.ago, auto_seen.ago)
        expect(described_class).to exist(notification.id)
      end

      it 'stays after auto seen time passes' do
        travel auto_seen + 1.minute
        described_class.cleanup(max_age.ago, own_seen.ago, auto_seen.ago)
        expect(described_class).to exist(notification.id)
      end

      it 'deleted after max time passes' do
        travel max_age + 1.day
        described_class.cleanup(max_age.ago, own_seen.ago, auto_seen.ago)
        expect(described_class).not_to exist(notification.id)
      end
    end

    describe 'notifying agents' do
      it 'notifies agents affected by both cleanup strategies' do
        agent2 = create(:agent)
        agent3 = create(:agent)

        create(:online_notification, user: user,   seen: false, created_at: 1.year.ago)
        create(:online_notification, user: user,   seen: true,  updated_at: 1.month.ago)
        create(:online_notification, user: agent2, seen: true,  updated_at: 1.month.ago)
        create(:online_notification, user: agent3, seen: false)

        allow(described_class).to receive(:cleanup_notify_agents)

        described_class.cleanup

        expect(described_class)
          .to have_received(:cleanup_notify_agents).with(contain_exactly(user.id, agent2.id))
      end
    end
  end

  describe '.cleanup_notify_agents' do
    it 'sends notifications to given users' do
      agent1 = create(:agent)
      _      = create(:agent)

      allow(Sessions).to receive(:send_to)

      described_class.cleanup_notify_agents([agent1])

      expect(Sessions).to have_received(:send_to).once
    end
  end

  describe '.seen_state?' do
    let(:group)    { create(:group) }
    let(:agent1)   { create(:agent, groups: [group]) }
    let(:agent2)   { create(:agent, groups: [group]) }
    let(:customer) { create(:customer) }
    let(:system)   { User.lookup(login: '-') }

    let(:ticket) do
      create(:ticket,
             group:         group,
             customer:      customer,
             owner_id:      owner_id,
             state_name:    state_name,
             updated_by_id: editor_id)
    end

    let(:first_article) do
      create(:ticket_article, :inbound_email, ticket: ticket)
    end

    context 'when state is new' do
      let(:state_name) { 'new' }
      let(:owner_id)   { agent1.id }
      let(:editor_id)  { 1 }

      it { expect(described_class).not_to be_seen_state(ticket) }
      it { expect(described_class).not_to be_seen_state(ticket, agent1.id) }
      it { expect(described_class).not_to be_seen_state(ticket, agent2.id) }
    end

    context 'when state is pending reminder' do
      let(:state_name) { 'pending reminder' }

      context 'when owner is an agent and updated by another agent' do
        let(:owner_id)  { agent1.id }
        let(:editor_id) { agent2.id }

        it { expect(described_class).to be_seen_state(ticket) }
        it { expect(described_class).not_to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).to be_seen_state(ticket, agent2.id) }
      end

      context 'when owner is system and updated by agent' do
        let(:owner_id)  { 1 }
        let(:editor_id) { agent2.id }

        it { expect(described_class).to be_seen_state(ticket) }
        it { expect(described_class).not_to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).not_to be_seen_state(ticket, agent2.id) }
      end

      context 'when updated by owner' do
        let(:owner_id)  { agent1.id }
        let(:editor_id) { agent1.id }

        it { expect(described_class).to be_seen_state(ticket) }
        it { expect(described_class).to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).to be_seen_state(ticket, agent2.id) }
      end
    end

    context 'when state is pending close' do
      let(:state_name) { 'pending close' }

      context 'when updated by owner' do
        let(:owner_id)  { agent1.id }
        let(:editor_id) { agent1.id }

        it { expect(described_class).to be_seen_state(ticket) }
        it { expect(described_class).to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).to be_seen_state(ticket, agent2.id) }
      end

      context 'when owner is an agent and updated by another agent' do
        let(:owner_id)  { agent1.id }
        let(:editor_id) { agent2.id }

        it { expect(described_class).to be_seen_state(ticket) }
        it { expect(described_class).not_to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).to be_seen_state(ticket, agent2.id) }
      end

      context 'when owner is system and updated by agent' do
        let(:owner_id)  { 1 }
        let(:editor_id) { agent2.id }

        it { expect(described_class).to be_seen_state(ticket) }
        it { expect(described_class).to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).to be_seen_state(ticket, agent2.id) }
      end
    end

    context 'when state is open' do
      let(:state_name) { 'open' }

      context 'when updated by owner' do
        let(:owner_id)  { agent1.id }
        let(:editor_id) { agent1.id }

        it { expect(described_class).not_to be_seen_state(ticket) }
        it { expect(described_class).not_to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).not_to be_seen_state(ticket, agent2.id) }
      end

      context 'when owner is an agent and updated by another agent' do
        let(:owner_id)  { agent1.id }
        let(:editor_id) { agent2.id }

        it { expect(described_class).not_to be_seen_state(ticket) }
        it { expect(described_class).not_to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).not_to be_seen_state(ticket, agent2.id) }
      end

      context 'when owner is system and updated by agent' do
        let(:owner_id)  { 1 }
        let(:editor_id) { agent2.id }

        it { expect(described_class).not_to be_seen_state(ticket) }
        it { expect(described_class).not_to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).not_to be_seen_state(ticket, agent2.id) }
      end
    end

    context 'when state is closed' do
      let(:state_name) { 'closed' }

      context 'when updated by owner' do
        let(:owner_id)  { agent1.id }
        let(:editor_id) { agent1.id }

        it { expect(described_class).to be_seen_state(ticket) }
        it { expect(described_class).to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).to be_seen_state(ticket, agent2.id) }
      end

      context 'when owner is an agent and updated by another agent' do
        let(:owner_id)  { agent1.id }
        let(:editor_id) { agent2.id }

        it { expect(described_class).to be_seen_state(ticket) }
        it { expect(described_class).not_to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).to be_seen_state(ticket, agent2.id) }
      end

      context 'when owner is system and updated by agent' do
        let(:owner_id)  { 1 }
        let(:editor_id) { agent2.id }

        it { expect(described_class).to be_seen_state(ticket) }
        it { expect(described_class).to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).to be_seen_state(ticket, agent2.id) }
      end
    end

    context 'when state is merged' do
      let(:state_name) { 'merged' }

      context 'when updated by owner' do
        let(:owner_id)  { agent1.id }
        let(:editor_id) { agent1.id }

        it { expect(described_class).to be_seen_state(ticket) }
        it { expect(described_class).to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).to be_seen_state(ticket, agent2.id) }
      end

      context 'when owner is an agent and updated by another agent' do
        let(:owner_id)  { agent1.id }
        let(:editor_id) { agent2.id }

        it { expect(described_class).to be_seen_state(ticket) }
        it { expect(described_class).to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).to be_seen_state(ticket, agent2.id) }
      end

      context 'when owner is system and updated by agent' do
        let(:owner_id)  { 1 }
        let(:editor_id) { agent2.id }

        it { expect(described_class).to be_seen_state(ticket) }
        it { expect(described_class).to be_seen_state(ticket, agent1.id) }
        it { expect(described_class).to be_seen_state(ticket, agent2.id) }
      end
    end
  end
end
