# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Chat::Session, type: :model do

  describe '.search_index_attribute_lookup' do
    subject(:chat_session) { create(:'chat/session', user: chat_user, chat: chat) }

    let(:chat_message) { create(:'chat/message', chat_session: chat_session) }

    let(:chat) { create(:chat) }
    let(:chat_user) { create(:agent) }

    before do
      chat_message
    end

    it 'verify message attribute' do
      expect(chat_session.search_index_attribute_lookup['messages']).not_to eq []
    end

    it 'verify user attribute' do
      expect(chat_session.search_index_attribute_lookup['user']['id']).to eq chat_user.id
    end

    it 'verify chat attribute' do
      expect(chat_session.search_index_attribute_lookup['chat']['name']).to eq chat.name
    end
  end

  describe '#running_for?' do
    let(:agent)   { create(:agent) }
    let(:session) { create(:'chat/session', chat: create(:chat), state:, user: agent) }
    let(:state)   { 'running' }

    it 'is true for the agent of a running session' do
      expect(session).to be_running_for(agent)
    end

    it 'is false for another agent' do
      expect(session).not_to be_running_for(create(:agent))
    end

    %w[waiting closed].each do |other_state|
      context "with a #{other_state} session that keeps its agent" do
        let(:state) { other_state }

        it 'is false' do
          expect(session).not_to be_running_for(agent)
        end
      end
    end
  end

  describe '#recipients_active?' do
    let(:chat)                  { create(:chat) }
    let(:agent)                 { create(:agent) }
    let(:customer_client)       { SecureRandom.uuid }
    let(:agent_client)          { SecureRandom.uuid }
    let(:previous_agent_client) { SecureRandom.uuid }
    let(:state)                 { 'running' }
    let(:participants)          { [customer_client, agent_client] }
    let(:session)               { create(:'chat/session', chat:, state:, user: agent, preferences: { participants: }) }

    # The widget of a customer connects without a login, the clients of agents carry their user.
    def connect_customer
      Sessions.create(customer_client, {}, {})
    end

    def connect_agent
      Sessions.create(agent_client, { 'id' => agent.id }, {})
    end

    def connect_previous_agent
      Sessions.create(previous_agent_client, { 'id' => create(:agent).id }, {})
    end

    def beat(time)
      create(:'chat/agent', updated_by: agent).update_columns(updated_at: time)
    end

    after do
      [customer_client, agent_client, previous_agent_client].each { |client_id| Sessions.destroy(client_id) }
    end

    context 'with a running session of an agent of the old UI' do
      it 'is true while both are connected' do
        connect_customer
        connect_agent

        expect(session).to be_recipients_active
      end

      it 'is false once the customer is gone, however fresh the beat of the agent is' do
        connect_agent
        beat(10.seconds.ago)

        expect(session).not_to be_recipients_active
      end

      it 'is false once the agent is gone and their beat is stale' do
        connect_customer
        beat(3.minutes.ago)

        expect(session).not_to be_recipients_active
      end
    end

    context 'with a running session of an agent of the new UI, who has no client' do
      let(:participants) { [customer_client] }

      before { connect_customer }

      it 'is true while the customer is connected and the agent beats' do
        beat(1.minute.ago)

        expect(session).to be_recipients_active
      end

      it 'is false once the beat is older than two minutes' do
        beat(3.minutes.ago)

        expect(session).not_to be_recipients_active
      end

      it 'is false without any beat' do
        expect(session).not_to be_recipients_active
      end

      it 'is false once the customer is gone, however fresh the beat is' do
        Sessions.destroy(customer_client)
        beat(10.seconds.ago)

        expect(session).not_to be_recipients_active
      end
    end

    # A transfer in the old UI leaves the client of the agent among the participants, and an accept in the
    #   new UI adds none.
    context 'with a running session that an agent of the old UI transferred and one of the new UI took' do
      let(:participants) { [customer_client, previous_agent_client] }

      before { connect_previous_agent }

      it 'is true while the customer is connected and the agent beats' do
        connect_customer
        beat(1.minute.ago)

        expect(session).to be_recipients_active
      end

      it 'is false once the customer is gone, however long the previous agent stays' do
        beat(10.seconds.ago)

        expect(session).not_to be_recipients_active
      end

      it 'is false once the agent is gone, however long the previous agent stays' do
        connect_customer
        beat(3.minutes.ago)

        expect(session).not_to be_recipients_active
      end
    end

    context 'with a waiting session' do
      let(:state) { 'waiting' }

      it 'is false with one connected participant, whoever it is' do
        connect_customer
        beat(10.seconds.ago)

        expect(session).not_to be_recipients_active
      end

      it 'is true with two connected participants' do
        connect_customer
        connect_agent

        expect(session).to be_recipients_active
      end
    end

    context 'without participants' do
      let(:session) { create(:'chat/session', chat:, state: 'running', user: agent) }

      it 'is true' do
        expect(session).to be_recipients_active
      end
    end
  end

  describe '.claim_next' do
    let(:chat)        { create(:chat, name: 'Support') }
    let(:other_chat)  { create(:chat, name: 'Sales') }
    let(:agent)       { create(:agent) }
    let(:other_agent) { create(:agent) }

    def waiting_session(created_at:, chat: self.chat)
      create(:'chat/session', chat:, state: 'waiting', created_at:)
    end

    it 'hands the oldest waiting session of the topics to the agent', :aggregate_failures do
      newer = waiting_session(created_at: 5.minutes.ago)
      older = waiting_session(created_at: 10.minutes.ago)

      claimed = described_class.claim_next([chat.id], agent)

      expect(claimed).to eq(older)
      expect(claimed).to have_attributes(state: 'running', user_id: agent.id)
      expect(newer.reload).to have_attributes(state: 'waiting', user_id: nil)
    end

    it 'only looks at the given topics' do
      waiting_session(created_at: 10.minutes.ago, chat: other_chat)
      wanted = waiting_session(created_at: 5.minutes.ago)

      expect(described_class.claim_next([chat.id], agent)).to eq(wanted)
    end

    it 'returns nothing for an empty queue' do
      create(:'chat/session', chat:, state: 'running', user: other_agent)

      expect(described_class.claim_next([chat.id], agent)).to be_nil
    end

    it 'leaves the update time of the session fresh, which the cleanup relies on' do
      session = waiting_session(created_at: 10.minutes.ago)
      session.update_columns(updated_at: 10.minutes.ago)

      expect(described_class.claim_next([chat.id], agent).updated_at).to be_within(1.minute).of(Time.zone.now)
    end

    it 'goes on with the next session when another agent wins the first one meanwhile', :aggregate_failures do
      first  = waiting_session(created_at: 10.minutes.ago)
      second = waiting_session(created_at: 5.minutes.ago)

      # The other agent is quicker, between the list of candidates and the claim.
      raced      = false
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        next if raced || payload[:sql].exclude?('SELECT "chat_sessions"."id"')

        raced = true
        described_class.where(id: first.id).update_all(state: 'running', user_id: other_agent.id)
      end

      claimed = described_class.claim_next([chat.id], agent)

      expect(claimed).to eq(second)
      expect(first.reload).to have_attributes(state: 'running', user_id: other_agent.id)
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    it 'leaves a session that was moved to another topic meanwhile', :aggregate_failures do
      first  = waiting_session(created_at: 10.minutes.ago)
      second = waiting_session(created_at: 5.minutes.ago)

      # Another agent claims it and transfers it, so it waits again, but in a topic not asked for.
      raced      = false
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        next if raced || payload[:sql].exclude?('SELECT "chat_sessions"."id"')

        raced = true
        described_class.where(id: first.id).update_all(chat_id: other_chat.id, user_id: other_agent.id)
      end

      claimed = described_class.claim_next([chat.id], agent)

      expect(claimed).to eq(second)
      expect(first.reload).to have_attributes(state: 'waiting', chat_id: other_chat.id, user_id: other_agent.id)
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    it 'returns nothing when the other agent wins the last waiting session' do
      first = waiting_session(created_at: 10.minutes.ago)

      raced      = false
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        next if raced || payload[:sql].exclude?('SELECT "chat_sessions"."id"')

        raced = true
        described_class.where(id: first.id).update_all(state: 'running', user_id: other_agent.id)
      end

      expect(described_class.claim_next([chat.id], agent)).to be_nil
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    # The legacy accept saves the session afterwards, which tells the index on its own.
    it 'leaves the search index to the caller', performs_jobs: true do
      allow(SearchIndexBackend).to receive(:enabled?).and_return(true)
      waiting_session(created_at: 10.minutes.ago)
      agent
      clear_jobs

      expect { described_class.claim_next([chat.id], agent) }
        .not_to have_enqueued_job(SearchIndexJob)
    end
  end

  describe '#search_index_update_after_claim', performs_jobs: true do
    let!(:session) { create(:'chat/session', chat: create(:chat), state: 'running') }

    before { clear_jobs }

    it 'tells the search index about the session' do
      allow(SearchIndexBackend).to receive(:enabled?).and_return(true)

      expect { session.search_index_update_after_claim }
        .to have_enqueued_job(SearchIndexJob).with('Chat::Session', session.id)
    end

    it 'tells the search index about the associations of the session' do
      allow(SearchIndexBackend).to receive(:enabled?).and_return(true)

      expect { session.search_index_update_after_claim }
        .to have_enqueued_job(SearchIndexAssociationsJob).with('Chat::Session', session.id)
    end

    it 'does nothing without a search index' do
      allow(SearchIndexBackend).to receive(:enabled?).and_return(false)

      expect { session.search_index_update_after_claim }
        .not_to have_enqueued_job(SearchIndexJob)
    end
  end

  describe '#conversation_underway?' do
    let(:chat_session) { create(:'chat/session', chat: create(:chat)) }

    it 'is not before the first message' do
      expect(chat_session).not_to be_conversation_underway
    end

    it 'is once a message was written' do
      create(:'chat/message', chat_session:)

      expect(chat_session).to be_conversation_underway
    end
  end

  describe '#send_start_to_customer' do
    let(:agent)        { create(:agent) }
    let(:client_id)    { SecureRandom.uuid }
    let(:chat_session) { create(:'chat/session', chat: create(:chat), state: 'running', user: agent, preferences: { participants: [client_id] }) }

    before { allow(Sessions).to receive(:send) }

    it 'tells the customer which agent answers and says so', :aggregate_failures do
      expect(chat_session.send_start_to_customer).to be(true)
      expect(Sessions).to have_received(:send).with(client_id, include(event: 'chat_session_start'))
    end

    context 'when the conversation is underway' do
      before { create(:'chat/message', chat_session:) }

      it 'tells nobody and says so', :aggregate_failures do
        expect(chat_session.send_start_to_customer).to be(false)
        expect(Sessions).not_to have_received(:send).with(client_id, include(event: 'chat_session_start'))
      end
    end
  end

  describe '#send_to_recipients' do
    let(:agent)                  { create(:agent) }
    let(:client_id)              { SecureRandom.uuid }
    let(:state)                  { 'running' }
    let(:user)                   { agent }
    let(:chat_session)           { create(:'chat/session', chat: create(:chat), state:, user:, preferences: { participants: [client_id] }) }
    let(:chat_message)           { create(:'chat/message', chat_session:) }
    let(:subscription)           { Gql::Subscriptions::Chat::SessionUpdates }
    let(:subscription_arguments) { { session_id: Gql::ZammadSchema.id_from_object(chat_session) } }

    before do
      allow(Sessions).to receive(:send)
      allow(subscription).to receive(:trigger)
    end

    it 'triggers the subscription of the session for a message' do
      chat_session.send_to_recipients({ event: 'chat_session_message', data: { message: chat_message } })

      expect(subscription).to have_received(:trigger).with({ message: chat_message }, arguments: subscription_arguments)
    end

    {
      'chat_session_notice' => [{ message: 'The customer moved on' }, { notice: 'The customer moved on' }],
      'chat_session_typing' => [{ user_id: nil }, { typing: true }],
      'chat_session_left'   => [{ realname: 'Anonymous' }, { left_by: 'Anonymous' }],
      'chat_session_closed' => [{ realname: 'System' }, { closed_by: 'System' }],
    }.each do |event, (data, payload)|
      it "triggers the subscription of the session for #{event}" do
        chat_session.send_to_recipients({ event:, data: })

        expect(subscription).to have_received(:trigger).with(payload, arguments: subscription_arguments)
      end
    end

    it 'delivers to the legacy clients as before' do
      message = { event: 'chat_session_notice', data: { message: 'The customer moved on' } }

      chat_session.send_to_recipients(message)

      expect(Sessions).to have_received(:send).with(client_id, message)
    end

    it 'triggers although the legacy client that caused the event is left out', :aggregate_failures do
      message = { event: 'chat_session_typing', data: { user_id: nil } }

      chat_session.send_to_recipients(message, client_id)

      expect(Sessions).not_to have_received(:send).with(client_id, anything)
      expect(subscription).to have_received(:trigger)
    end

    it 'does not trigger for what the agent types themself' do
      chat_session.send_to_recipients({ event: 'chat_session_typing', data: { user_id: agent.id } })

      expect(subscription).not_to have_received(:trigger)
    end

    %w[chat_session_queue chat_session_start].each do |event|
      it "does not trigger for #{event}, which is for the customer only" do
        chat_session.send_to_recipients({ event:, data: { state: 'ok' } })

        expect(subscription).not_to have_received(:trigger)
      end
    end

    # A transfer puts the session back into a queue without taking it from its agent.
    context 'when the session was sent back to a queue' do
      let(:state) { 'waiting' }

      it 'does not trigger' do
        chat_session.send_to_recipients({ event: 'chat_session_notice', data: { message: 'The customer moved on' } })

        expect(subscription).not_to have_received(:trigger)
      end
    end

    context 'when no agent runs the session yet' do
      let(:state) { 'waiting' }
      let(:user)  { nil }

      it 'does not trigger' do
        chat_session.send_to_recipients({ event: 'chat_session_notice', data: { message: 'The customer moved on' } })

        expect(subscription).not_to have_received(:trigger)
      end
    end
  end
end
