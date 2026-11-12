# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Enqueuing it is covered by spec/services/service/chat/session/accept_spec.rb.
RSpec.describe ChatGreetingJob, type: :job do
  let(:chat)            { create(:chat) }
  let(:agent)           { create(:agent) }
  let(:customer_client) { SecureRandom.uuid }
  let(:state)           { 'running' }
  let(:user)            { agent }
  let(:session)         { create(:'chat/session', chat:, state:, user:, preferences: { participants: [customer_client] }) }
  let(:phrase)          { 'Hello, I am Erika' }

  # The queue also carries the collection updates for users created meanwhile.
  def chat_messages_to_customer
    Sessions.queue(customer_client).select { |message| message['event'].start_with?('chat_') }
  end

  before do
    Setting.set('chat', true)

    Sessions.create(customer_client, {}, {})
    Sessions.queue(customer_client)
  end

  after { Sessions.destroy(customer_client) }

  describe '#perform' do
    subject(:perform) { described_class.perform_now(session.id, agent.id, phrase) }

    it 'writes the greeting as the agent', :aggregate_failures do
      perform

      expect(session.messages).to contain_exactly(have_attributes(content: 'Hello, I am Erika', created_by_id: agent.id))
    end

    it 'sends it to the customer like any message of the agent' do
      perform

      expect(chat_messages_to_customer).to contain_exactly(
        include('event' => 'chat_session_message', 'data' => include('session_id' => session.session_id, 'message' => include('content' => 'Hello, I am Erika'))),
      )
    end

    it 'sends it as text, not as markup' do
      described_class.perform_now(session.id, agent.id, '<b>Hello</b> & welcome')

      expect(session.messages.first.content).to eq('&lt;b&gt;Hello&lt;/b&gt; &amp; welcome')
    end

    context 'when a message was written meanwhile' do
      before { create(:'chat/message', chat_session: session) }

      it 'sends nothing' do
        expect { perform }.not_to change(Chat::Message, :count)
      end
    end

    # Another job for the session, or a message of the agent, that commits while this job waits for the lock.
    context 'when a message is written while the job waits for the lock' do
      before do
        allow(Chat::Session).to receive(:find_by).with(id: session.id).and_return(session)
        allow(session).to receive(:with_lock).and_wrap_original do |original, *args, &block|
          create(:'chat/message', chat_session: session)
          original.call(*args, &block)
        end
      end

      it 'sends nothing', :aggregate_failures do
        perform

        expect(session.messages.count).to eq(1)
        expect(chat_messages_to_customer).to be_empty
      end
    end

    context 'when the session is closed' do
      let(:state) { 'closed' }

      it 'sends nothing' do
        expect { perform }.not_to change(Chat::Message, :count)
      end
    end

    context 'when the session waits again after a transfer' do
      let(:state) { 'waiting' }

      it 'sends nothing' do
        expect { perform }.not_to change(Chat::Message, :count)
      end
    end

    context 'when another agent runs the session' do
      let(:user) { create(:agent) }

      it 'sends nothing' do
        expect { perform }.not_to change(Chat::Message, :count)
      end
    end

    context 'when the session is gone' do
      it 'sends nothing' do
        id = session.id
        session.destroy!

        expect { described_class.perform_now(id, agent.id, phrase) }.not_to change(Chat::Message, :count)
      end
    end

    context 'when the agent is gone' do
      it 'sends nothing' do
        session
        agent_id = agent.id
        session.update!(user: nil)
        agent.destroy!

        expect { described_class.perform_now(session.id, agent_id, phrase) }.not_to change(Chat::Message, :count)
      end
    end
  end
end
