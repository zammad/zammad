# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The legacy counterpart is spec/lib/sessions/event/chat_session_start_spec.rb, the claim itself
#   is covered by spec/models/chat/session_spec.rb.
RSpec.describe Service::Chat::Session::Accept do
  subject(:service) { described_class.with_current_user(agent).execute(**arguments) }

  let(:arguments)          { {} }
  let(:topic)              { create(:chat, name: 'Support') }
  let(:other_topic)        { create(:chat, name: 'Sales') }
  let(:preferences)        { { chat: { active: { topic.id.to_s => 'on' } } } }
  let(:agent)              { create(:agent, firstname: 'Chat', lastname: 'Agent', preferences:) }
  let(:customer)           { create(:customer) }
  let(:customer_client_id) { SecureRandom.uuid }
  let!(:older_session)     { create(:'chat/session', chat: topic, state: 'waiting', created_at: 10.minutes.ago, preferences: { participants: [customer_client_id] }) }
  let!(:newer_session)     { create(:'chat/session', chat: topic, state: 'waiting', created_at: 5.minutes.ago, preferences: { participants: [customer_client_id] }) }

  # The queue also carries the collection updates for users created meanwhile.
  def chat_messages_to_customer
    Sessions.queue(customer_client_id).select { |message| message['event'].start_with?('chat_') }
  end

  before do
    Setting.set('chat', true)

    Sessions.create(customer_client_id, { 'id' => customer.id }, {})
    Sessions.queue(customer_client_id)

    allow(Chat).to receive(:broadcast_agent_state_update)
    allow(Chat).to receive(:broadcast_customer_state_update)
  end

  it 'requires a current user' do
    expect { described_class.execute }.to raise_error(%r{Current user is required})
  end

  context 'without a topic' do
    it 'hands the oldest waiting session of the topics the agent handles to them', :aggregate_failures do
      expect(service).to eq(older_session)
      expect(service).to have_attributes(state: 'running', user_id: agent.id)
      expect(newer_session.reload).to have_attributes(state: 'waiting', user_id: nil)
    end

    it 'leaves the sessions of other topics alone' do
      older_session.update!(chat: other_topic)

      expect(service).to eq(newer_session)
    end

    # Like the legacy event: the start of the conversation counts, not the time of the transfer.
    context 'with a session transferred after another customer started waiting' do
      let(:other_agent) { create(:agent) }

      before do
        older_session.update!(chat: other_topic, state: 'running', user: other_agent)
        Service::Chat::Session::Transfer.with_current_user(other_agent).execute(session: older_session, topic:)
      end

      it 'hands the transferred session to the agent first' do
        expect(service).to eq(older_session)
      end
    end

    # The agent has no legacy client id to add.
    it 'adds no recipient' do
      service

      expect(older_session.reload.preferences[:participants]).to eq([customer_client_id])
    end
  end

  context 'with a topic' do
    let(:arguments)      { { topic: other_topic } }
    let!(:sales_session) { create(:'chat/session', chat: other_topic, state: 'waiting', preferences: { participants: [customer_client_id] }) }

    it 'hands the oldest waiting session of that topic to the agent, handled or not' do
      expect(service).to eq(sales_session)
    end
  end

  context 'when the customer is told who answers' do
    it 'sends the agent name to the widget, without an avatar for an agent without a picture', :aggregate_failures do
      service

      expect(chat_messages_to_customer).to eq([
                                                {
                                                  'event' => 'chat_session_start',
                                                  'data'  => {
                                                    'state'      => 'ok',
                                                    'agent'      => { 'name' => 'Chat Agent', 'avatar' => nil },
                                                    'session_id' => older_session.session_id,
                                                    'chat_id'    => topic.id,
                                                  },
                                                },
                                              ])
    end

    context 'with an alternative name and the avatar disabled' do
      let(:preferences) { { chat: { active: { topic.id.to_s => 'on' }, alternative_name: 'some name', avatar_state: 'disabled' } } }

      it 'sends the alternative name without an avatar' do
        service

        expect(chat_messages_to_customer.first['data']['agent']).to eq({ 'name' => 'some name', 'avatar' => nil })
      end
    end

    # A transferred conversation is underway for the customer already.
    context 'when the conversation has messages already' do
      before { create(:'chat/message', chat_session: older_session) }

      it 'stays quiet' do
        service

        expect(chat_messages_to_customer).to be_empty
      end
    end
  end

  # The old interface greets from the browser, see spec/lib/sessions/event/chat_session_start_spec.rb for
  #   the legacy accept, which does not. Sending it is covered by spec/jobs/chat_greeting_job_spec.rb.
  describe 'the greeting', performs_jobs: true do
    let(:phrases)     { 'Hello, I am Erika; Good day ;;' }
    let(:preferences) { { chat: { active: { topic.id.to_s => 'on' }, phrase: { topic.id.to_s => phrases } } } }

    def enqueued_greetings
      enqueued_jobs.select { |job| job['job_class'] == 'ChatGreetingJob' }
    end

    it 'has one of the alternatives sent for the accepted session shortly after', :aggregate_failures do
      freeze_time

      expect { service }
        .to have_enqueued_job(ChatGreetingJob)
        .with(older_session.id, agent.id, a_string_matching(%r{\A(Hello, I am Erika|Good day)\z}))
        .at(1.6.seconds.from_now)
    end

    # The job starts at the first poll after the delay, too late to keep a typing signal of the widget up.
    it 'does not show the customer that the agent is typing' do
      service

      expect(chat_messages_to_customer.pluck('event')).to eq(%w[chat_session_start])
    end

    context 'when the greeting cannot be scheduled' do
      before do
        allow(ChatGreetingJob).to receive(:set).and_raise(StandardError, 'queue is down')
        allow(Rails.logger).to receive(:error)
      end

      it 'still hands the session to the agent and logs the failure', :aggregate_failures do
        expect(service).to have_attributes(id: older_session.id, state: 'running', user_id: agent.id)
        expect(Rails.logger).to have_received(:error)
      end
    end

    context 'with the greetings saved in the chat settings' do
      let(:preferences) { {} }

      before do
        Service::Chat::Preferences::Update.with_current_user(agent).execute(
          topics: [{ topic: topic, active: true, phrases: ['Hello, I am Erika'] }],
        )
      end

      it 'sends them' do
        expect { service }.to have_enqueued_job(ChatGreetingJob).with(older_session.id, agent.id, 'Hello, I am Erika')
      end
    end

    context 'with the topic id stored as a number' do
      let(:preferences) { { chat: { active: { topic.id => 'on' }, phrase: { topic.id => 'Hello, I am Erika' } } } }

      it 'sends the greeting' do
        expect { service }.to have_enqueued_job(ChatGreetingJob).with(older_session.id, agent.id, 'Hello, I am Erika')
      end
    end

    context 'with a topic the agent does not handle' do
      let(:arguments)   { { topic: other_topic } }
      let(:preferences) { { chat: { active: { topic.id.to_s => 'on' }, phrase: { topic.id.to_s => 'Support greeting', other_topic.id.to_s => 'Sales greeting' } } } }

      before { create(:'chat/session', chat: other_topic, state: 'waiting', preferences: { participants: [customer_client_id] }) }

      it 'sends the greeting of the topic of the session' do
        expect { service }.to have_enqueued_job(ChatGreetingJob).with(anything, agent.id, 'Sales greeting')
      end
    end

    context 'with a conversation that has messages already' do
      before { create(:'chat/message', chat_session: older_session) }

      it 'sends none' do
        service

        expect(enqueued_greetings).to be_empty
      end
    end

    context 'with a greeting for another topic only' do
      let(:preferences) { { chat: { active: { topic.id.to_s => 'on' }, phrase: { other_topic.id.to_s => 'Sales greeting' } } } }

      it 'sends none' do
        service

        expect(enqueued_greetings).to be_empty
      end
    end

    context 'with blank greetings only' do
      let(:phrases) { ' ; ;' }

      it 'sends none' do
        service

        expect(enqueued_greetings).to be_empty
      end
    end

    context 'without any greetings' do
      let(:preferences) { { chat: { active: { topic.id.to_s => 'on' } } } }

      it 'sends none' do
        service

        expect(enqueued_greetings).to be_empty
      end
    end
  end

  it 'tells the agents of the topic, the accepting agent included, and the other waiting customers', :aggregate_failures do
    service

    expect(Chat).to have_received(:broadcast_agent_state_update).with([topic.id], agent_ids: [agent.id])
    expect(Chat).to have_received(:broadcast_customer_state_update).with(topic.id)
  end

  # The claim runs no callbacks, and nothing saves the session afterwards.
  it 'tells the search index about the accepted session', performs_jobs: true do
    allow(SearchIndexBackend).to receive(:enabled?).and_return(true)
    clear_jobs

    expect { service }.to have_enqueued_job(SearchIndexJob).with('Chat::Session', older_session.id)
  end

  context 'with nobody waiting' do
    before { Chat::Session.where(state: 'waiting').update_all(state: 'closed') }

    it 'fails with the message of the old interface' do
      expect { service }.to raise_error(Exceptions::UnprocessableContent, 'No session available.')
    end

    it 'tells nobody', :aggregate_failures do
      expect { service }.to raise_error(Exceptions::UnprocessableContent)

      expect(Chat).not_to have_received(:broadcast_agent_state_update)
      expect(Chat).not_to have_received(:broadcast_customer_state_update)
    end
  end

  context 'when another agent took the only waiting session meanwhile' do
    before do
      newer_session.update!(state: 'closed')
      Chat::Session.claim_next([topic.id], create(:agent))
    end

    it 'fails the same way' do
      expect { service }.to raise_error(Exceptions::UnprocessableContent, 'No session available.')
    end
  end
end
