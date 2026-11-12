# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Chat::AgentState do
  subject(:state) { described_class.with_current_user(agent).execute }

  let(:topic)       { create(:chat, name: 'Support') }
  let(:other_topic) { create(:chat, name: 'Sales') }
  let(:agent)       { create(:agent, preferences: { chat: { active: { topic.id.to_s => 'on' } } }) }
  let(:colleague)   { create(:agent, preferences: { chat: { active: { topic.id.to_s => 'on' } } }) }

  def make_available(user, concurrent: 4, active: true)
    create(:'chat/agent', concurrent:, active:, updated_by: user, created_by: user)
  end

  def waiting_sessions
    state[:waiting_queues].map { |queue| [queue[:topic], queue[:sessions].to_a] }
  end

  before { Setting.set('chat', true) }

  it 'requires a current user' do
    expect { described_class.execute }.to raise_error(%r{Current user is required})
  end

  it 'lists the active topics by name' do
    topic
    other_topic
    create(:chat, name: 'Inactive', active: false)
    Chat.find_by(name: 'default').update!(active: false)

    expect(state[:topics]).to eq([other_topic, topic])
  end

  context 'when the agent never switched availability on' do
    it 'reports them unavailable with empty queues and no seats', :aggregate_failures do
      expect(state).to include(active: false, available_agents: [], seats_available: 0, seats_total: 0)
      expect(waiting_sessions).to eq([[topic, []]])
      expect(state[:running_sessions]).to be_empty
    end
  end

  context 'when the agent switched availability off' do
    before { make_available(agent, active: false) }

    it 'reports them unavailable and does not count their seats' do
      expect(state).to include(active: false, available_agents: [], seats_total: 0)
    end
  end

  context 'when the agent is available' do
    before { make_available(agent, concurrent: 4) }

    it 'reports them available with their own seats', :aggregate_failures do
      expect(state).to include(active: true, available_agents: [agent], seats_available: 4, seats_total: 4)
    end

    context 'with waiting customers' do
      let!(:newer) { create(:'chat/session', chat: topic, state: 'waiting') }
      let!(:older) { travel_to(1.minute.ago) { create(:'chat/session', chat: topic, state: 'waiting') } }

      before { create(:'chat/session', chat: other_topic, state: 'waiting') }

      it 'lists those of the handled topic, longest waiting first' do
        expect(waiting_sessions).to eq([[topic, [older, newer]]])
      end

      it 'counts them against the seats of the handled topic' do
        expect(state).to include(seats_available: 2, seats_total: 4)
      end
    end

    context 'with running sessions' do
      let!(:own)        { travel_to(1.minute.ago) { create(:'chat/session', chat: topic, state: 'running', user: agent) } }
      let!(:colleagues) { create(:'chat/session', chat: topic, state: 'running', user: colleague) }

      before do
        create(:'chat/session', chat: topic, state: 'closed', user: agent)
        create(:'chat/session', chat: other_topic, state: 'running', user: colleague)
      end

      it 'lists the running ones of the handled topic, with any agent, oldest first' do
        expect(state[:running_sessions]).to eq([own, colleagues])
      end

      it 'counts them against the seats' do
        expect(state).to include(seats_available: 2)
      end
    end

    context 'with a running session of the agent in a topic they do not handle' do
      let!(:elsewhere) { create(:'chat/session', chat: other_topic, state: 'running', user: agent) }
      let!(:handled)   { create(:'chat/session', chat: topic, state: 'running', user: colleague) }

      before { create(:'chat/session', chat: other_topic, state: 'running', user: colleague) }

      it 'lists it besides those of the handled topic, but not a colleague\'s in the other one' do
        expect(state[:running_sessions]).to eq([elsewhere, handled])
      end
    end

    context 'with a colleague available for the same topic' do
      before { make_available(colleague, concurrent: 2) }

      it 'lists both and adds up the seats', :aggregate_failures do
        expect(state[:available_agents]).to contain_exactly(agent, colleague)
        expect(state).to include(seats_available: 6, seats_total: 6)
      end
    end

    context 'with a colleague available for another topic only' do
      let(:colleague) { create(:agent, preferences: { chat: { active: { other_topic.id.to_s => 'on' } } }) }

      before { make_available(colleague, concurrent: 2) }

      it 'does not list them', :aggregate_failures do
        expect(state[:available_agents]).to eq([agent])
        expect(state).to include(seats_total: 4)
      end
    end

    context 'with a colleague whose availability is stale' do
      before { travel_to(3.minutes.ago) { make_available(colleague, concurrent: 2) } }

      it 'does not list them', :aggregate_failures do
        expect(state[:available_agents]).to eq([agent])
        expect(state).to include(seats_total: 4)
      end
    end

    context 'with a colleague who switched availability off' do
      before { make_available(colleague, concurrent: 2, active: false) }

      it 'does not list them' do
        expect(state[:available_agents]).to eq([agent])
      end
    end

    context 'when the agent handles two topics' do
      let(:agent) { create(:agent, preferences: { chat: { active: { topic.id.to_s => 'on', other_topic.id.to_s => 'on' } } }) }

      let!(:support_session) { create(:'chat/session', chat: topic, state: 'waiting') }
      let!(:sales_session)   { create(:'chat/session', chat: other_topic, state: 'waiting') }

      it 'lists a queue per topic, by name' do
        expect(waiting_sessions).to eq([[other_topic, [sales_session]], [topic, [support_session]]])
      end
    end

    context 'when the agent handles a topic that was deactivated' do
      let(:topic) { create(:chat, name: 'Support', active: false) }

      it 'lists no queue for it' do
        expect(waiting_sessions).to be_empty
      end
    end

    # Like the old UI: an agent who never chose a topic counts as handling every topic
    #   (Chat.agent_active_chat?), so they see themself as available, but nothing to handle.
    context 'when the agent handles no topic' do
      let(:agent) { create(:agent) }

      before do
        make_available(colleague, concurrent: 2)
        create(:'chat/session', chat: topic, state: 'waiting')
      end

      it 'sees no queues, no sessions and no colleague', :aggregate_failures do
        expect(state).to include(active: true, available_agents: [agent], seats_available: 4, seats_total: 4)
        expect(waiting_sessions).to be_empty
        expect(state[:running_sessions]).to be_empty
      end
    end
  end
end
