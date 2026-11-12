# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Reading them typed is covered by spec/graphql/gql/queries/chat/preferences_spec.rb.
RSpec.describe Service::Chat::Preferences::Update do
  subject(:service) { described_class.with_current_user(agent).execute(**arguments) }

  let(:arguments)   { {} }
  let(:support)     { create(:chat, name: 'Support') }
  let(:sales)       { create(:chat, name: 'Sales') }
  let(:preferences) { {} }
  let(:agent)       { create(:agent, firstname: 'Chat', lastname: 'Agent', preferences:) }

  def stored_chat_preferences
    agent.reload.preferences[:chat]
  end

  it 'requires a current user' do
    expect { described_class.execute }.to raise_error(%r{Current user is required})
  end

  it 'returns the stored chat preferences' do
    expect(described_class.with_current_user(agent).execute(max_windows: 7)).to include('max_windows' => 7)
  end

  context 'with the topics to take' do
    let(:arguments) { { topics: [{ topic: support, active: true, phrases: [] }, { topic: sales, active: false, phrases: [] }] } }

    it 'stores them as the old interface does and Chat.agent_active_chat_ids reads them', :aggregate_failures do
      service

      expect(stored_chat_preferences['active']).to eq({ support.id.to_s => 'on' })
      expect(Chat.agent_active_chat_ids(agent.reload)).to eq([support.id])
    end
  end

  context 'with topics that were taken before' do
    let(:preferences) { { chat: { active: { support.id.to_s => 'on', sales.id.to_s => 'on' } } } }

    it 'drops the one given as not taken, and leaves the others alone', :aggregate_failures do
      described_class.with_current_user(agent).execute(topics: [{ topic: support, active: false, phrases: [] }])

      expect(stored_chat_preferences['active']).to eq({ sales.id.to_s => 'on' })
    end

    it 'leaves them alone without topics' do
      described_class.with_current_user(agent).execute(max_windows: 6)

      expect(stored_chat_preferences['active']).to eq({ support.id.to_s => 'on', sales.id.to_s => 'on' })
    end
  end

  context 'with greetings' do
    let(:arguments) { { topics: [{ topic: support, active: true, phrases: ['Hello, I am Erika', '', 'Good day'] }, { topic: sales, active: true, phrases: [] }] } }

    it 'joins them by semicolon under the topic, and stores none for a topic without', :aggregate_failures do
      service

      expect(stored_chat_preferences['phrase']).to eq({ support.id.to_s => 'Hello, I am Erika;Good day' })
    end

    context 'with a semicolon inside a greeting' do
      let(:arguments) { { topics: [{ topic: support, active: true, phrases: ['Hi; how can I help?', 'Good day'] }] } }

      it 'turns it into a comma, so the old interface does not read two greetings' do
        service

        expect(stored_chat_preferences['phrase']).to eq({ support.id.to_s => 'Hi, how can I help?;Good day' })
      end
    end
  end

  context 'with the name and the avatar' do
    let(:arguments) { { alternative_name: 'some name', avatar_enabled: false } }

    it 'stores them where the widget reads them', :aggregate_failures do
      service
      chat_session = create(:'chat/session', chat: support, state: 'running', user: agent)

      expect(stored_chat_preferences).to include('alternative_name' => 'some name', 'avatar_state' => 'disabled')
      expect(chat_session.agent_user).to eq({ name: 'some name', avatar: nil })
    end

    context 'when switching the avatar on and the name off again' do
      let(:preferences) { { chat: { alternative_name: 'some name', avatar_state: 'disabled' } } }
      let(:arguments)   { { alternative_name: '', avatar_enabled: true } }

      it 'stores the state of the old interface' do
        service

        expect(stored_chat_preferences).to include('alternative_name' => '', 'avatar_state' => 'enabled')
      end
    end
  end

  describe 'the limit of concurrent chats' do
    [1, 20].each do |value|
      context "with #{value}" do
        let(:arguments) { { max_windows: value } }

        it 'stores it as a number' do
          service

          expect(stored_chat_preferences['max_windows']).to eq(value)
        end
      end
    end

    [0, 21, -3].each do |value|
      context "with #{value}" do
        let(:arguments) { { max_windows: value } }

        it 'is refused and changes nothing', :aggregate_failures do
          expect { service }.to raise_error(Exceptions::UnprocessableContent, 'The number of concurrent chats must be between 1 and 20.')

          expect(stored_chat_preferences).to be_nil
        end
      end
    end
  end

  context 'with a limit stored as text by the old interface' do
    let(:preferences) { { chat: { 'max_windows' => '6', 'alternative_name' => 'Erika' } } }
    let(:arguments)   { { max_windows: 8 } }

    it 'replaces it and leaves what is not given', :aggregate_failures do
      service

      expect(stored_chat_preferences).to include('max_windows' => 8, 'alternative_name' => 'Erika')
    end
  end

  context 'with greetings stored before' do
    let(:preferences) { { chat: { phrase: { support.id.to_s => 'Hello, I am Erika', sales.id.to_s => 'Good day' } } } }

    it 'leaves the ones of a topic given without greetings alone, and replaces the ones of a topic given with', :aggregate_failures do
      described_class.with_current_user(agent).execute(topics: [{ topic: support, active: true }, { topic: sales, active: true, phrases: [] }])

      expect(stored_chat_preferences['active']).to eq({ support.id.to_s => 'on', sales.id.to_s => 'on' })
      expect(stored_chat_preferences['phrase']).to eq({ support.id.to_s => 'Hello, I am Erika' })
    end
  end

  context 'with other preferences of the user' do
    let(:preferences) { { cti: true, custom_key: 'kept', chat: { max_windows: 3 } } }
    let(:arguments)   { { max_windows: 5 } }

    it 'leaves them alone', :aggregate_failures do
      service

      expect(agent.reload.preferences).to include('cti' => true, 'custom_key' => 'kept')
      expect(stored_chat_preferences['max_windows']).to eq(5)
    end
  end

  # Whom a broadcast reaches is covered by spec/models/chat_spec.rb, the push itself by
  #   spec/graphql/gql/subscriptions/chat/agent_state_updates_spec.rb.
  describe 'the availability and the agents told' do
    let(:preferences) { { chat: { active: { support.id.to_s => 'on', sales.id.to_s => 'on' } } } }

    def take(**topics)
      described_class.with_current_user(agent).execute(topics: topics.map { |topic, active| { topic: public_send(topic), active: } })
    end

    def agents_told_of(*topic_ids)
      have_received(:broadcast_agent_state_update).with(a_collection_containing_exactly(*topic_ids), agent_ids: [agent.id])
    end

    before do
      allow(Chat).to receive(:broadcast_agent_state_update)
    end

    context 'when the agent is available' do
      before { create(:'chat/agent', active: true, updated_by: agent, created_by: agent) }

      it 'switches them unavailable when no topic stays taken, and tells them and the agents of the topics they left', :aggregate_failures do
        expect { take(support: false, sales: false) }.to change { Chat::Agent.state(agent.id) }.from(true).to(false)
        expect(Chat).to agents_told_of(support.id, sales.id)
      end

      it 'keeps them available while a topic stays taken, and tells them and the agents of the topic they left', :aggregate_failures do
        expect { take(support: false) }.not_to change { Chat::Agent.state(agent.id) }.from(true)
        expect(Chat).to agents_told_of(support.id, sales.id)
      end

      context 'with a single topic taken' do
        let(:preferences) { { chat: { active: { support.id.to_s => 'on' } } } }

        it 'tells them and the agents of the topic they take as well' do
          take(sales: true)

          expect(Chat).to agents_told_of(support.id, sales.id)
        end
      end

      it 'tells nobody when the topics stay as they were' do
        described_class.with_current_user(agent).execute(topics: [{ topic: support, active: true, phrases: ['Hello, I am Erika'] }])

        expect(Chat).not_to have_received(:broadcast_agent_state_update)
      end

      context 'with a topic the admin switched off left taken' do
        before { sales.update!(active: false) }

        it 'does not count it as a topic to take chats for', :aggregate_failures do
          expect { take(support: false) }.to change { Chat::Agent.state(agent.id) }.from(true).to(false)
          expect(Chat).to agents_told_of(support.id, sales.id)
        end
      end

      context 'without topics given' do
        let(:preferences) { {} }

        it 'leaves the availability alone and tells nobody', :aggregate_failures do
          expect { described_class.with_current_user(agent).execute(max_windows: 5) }.not_to change { Chat::Agent.state(agent.id) }.from(true)
          expect(Chat).not_to have_received(:broadcast_agent_state_update)
        end
      end
    end

    # The agents of the topics count only agents who are available.
    context 'when the agent is unavailable' do
      before { create(:'chat/agent', active: false, updated_by: agent, created_by: agent) }

      it 'tells only them when no topic stays taken', :aggregate_failures do
        expect { take(support: false, sales: false) }.not_to change { Chat::Agent.state(agent.id) }.from(false)
        expect(Chat).to agents_told_of
      end
    end

    context 'when the agent never stored an availability' do
      it 'stores none and tells only them', :aggregate_failures do
        expect { take(support: false, sales: false) }.not_to change(Chat::Agent, :count)
        expect(Chat).to agents_told_of
      end
    end
  end
end
