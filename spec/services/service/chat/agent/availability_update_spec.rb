# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Chat::Agent::AvailabilityUpdate do
  subject(:service) { described_class.with_current_user(agent).execute(active:) }

  let(:topic)  { create(:chat) }
  let(:agent)  { create(:agent, preferences: { chat: { active: { topic.id.to_s => 'on' } } }) }
  let(:active) { true }

  before do
    Setting.set('chat', true)
    Chat.where(active: true).update_all(active: false) # only the topics of the example count, not the seeded one
    allow(Chat).to receive(:broadcast_agent_state_update)
  end

  it 'requires a current user' do
    expect { described_class.execute(active:) }.to raise_error(%r{Current user is required})
  end

  context 'when the agent never switched availability' do
    it 'creates their agent row with the flag' do
      expect { service }.to change { Chat::Agent.state(agent.id) }.from(false).to(true)
    end

    # Named rather than ignored, unlike the legacy event: the actor's other windows get no reply.
    it 'tells the agents of their topics, the agent included' do
      service

      expect(Chat).to have_received(:broadcast_agent_state_update).with([topic.id], agent_ids: [agent.id])
    end

    it 'returns the new flag' do
      expect(service).to be(true)
    end
  end

  context 'when the agent is unavailable' do
    before { create(:'chat/agent', active: false, updated_by: agent, created_by: agent) }

    it 'switches them available and tells the agents of their topics', :aggregate_failures do
      expect { service }.to change { Chat::Agent.state(agent.id) }.from(false).to(true)
      expect(Chat).to have_received(:broadcast_agent_state_update).with([topic.id], agent_ids: [agent.id])
    end

    context 'when switching off again' do
      let(:active) { false }

      it 'leaves the flag and tells nobody', :aggregate_failures do
        expect { service }.not_to change { Chat::Agent.state(agent.id) }.from(false)
        expect(Chat).not_to have_received(:broadcast_agent_state_update)
      end

      it 'returns the flag' do
        expect(service).to be(false)
      end
    end
  end

  context 'when the agent is available' do
    let(:active) { false }

    before { create(:'chat/agent', active: true, updated_by: agent, created_by: agent) }

    it 'switches them unavailable and tells the agents of their topics', :aggregate_failures do
      expect { service }.to change { Chat::Agent.state(agent.id) }.from(true).to(false)
      expect(Chat).to have_received(:broadcast_agent_state_update).with([topic.id], agent_ids: [agent.id])
    end
  end

  context 'when the agent handles no topic' do
    let(:agent) { create(:agent) }

    # Parity with the legacy event: the prompt to choose a topic belongs to the chat panel.
    it 'switches them available anyway', :aggregate_failures do
      expect { service }.to change { Chat::Agent.state(agent.id) }.from(false).to(true)
      expect(Chat).to have_received(:broadcast_agent_state_update).with([], agent_ids: [agent.id])
    end

    context 'with a single topic' do
      before { topic }

      it 'takes the topic and tells the agents of it', :aggregate_failures do
        expect { service }.to change { Chat.agent_active_chat_ids(agent.reload) }.from([]).to([topic.id])
        expect(Chat).to have_received(:broadcast_agent_state_update).with([topic.id], agent_ids: [agent.id])
      end

      context 'with greetings stored for the topic' do
        let(:agent) { create(:agent, preferences: { chat: { phrase: { topic.id.to_s => 'Hello, I am Erika' } } }) }

        it 'keeps the greetings' do
          service

          expect(agent.reload.preferences[:chat]).to include(phrase: { topic.id.to_s => 'Hello, I am Erika' })
        end
      end

      context 'when switching off' do
        let(:active) { false }

        it 'takes no topic' do
          expect { service }.not_to change { Chat.agent_active_chat_ids(agent.reload) }.from([])
        end
      end

      context 'when the topic is inactive' do
        before { topic.update!(active: false) }

        it 'takes no topic' do
          expect { service }.not_to change { Chat.agent_active_chat_ids(agent.reload) }.from([])
        end
      end
    end

    context 'with several topics' do
      before do
        topic
        create(:chat)
      end

      it 'takes none and switches them available anyway', :aggregate_failures do
        expect { service }.to change { Chat::Agent.state(agent.id) }.from(false).to(true)
        expect(Chat.agent_active_chat_ids(agent.reload)).to eq([])
      end
    end
  end

  context 'when the agent handles a topic and there is another one' do
    before { create(:chat) }

    it 'leaves their choice alone' do
      expect { service }.not_to change { Chat.agent_active_chat_ids(agent.reload) }.from([topic.id])
    end
  end
end
