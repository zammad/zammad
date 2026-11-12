# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Chat::Session::Search do
  let(:topic)       { create(:chat, name: 'Support') }
  let(:agent)       { create(:agent) }
  let(:other_agent) { create(:agent, firstname: 'Berta', lastname: 'Beispiel') }

  describe '.search_preferences' do
    before { Setting.set('chat', chat_enabled) }

    context 'with the chat feature switched on' do
      let(:chat_enabled) { true }

      it 'offers the sessions to the global search, after the models of the old UI' do
        expect(Chat::Session.search_preferences(agent)).to eq(prio: 900, direct_search_index: true)
      end

      it 'is not searched for a user without the chat.agent permission' do
        user = create(:user, roles: [create(:role, permission_names: 'ticket.agent')])

        expect(Chat::Session.search_preferences(user)).to be(false)
      end
    end

    context 'with the chat feature switched off' do
      let(:chat_enabled) { false }

      it 'is not searched' do
        expect(Chat::Session.search_preferences(agent)).to be(false)
      end
    end
  end

  # What the old UI finds, with the search index and without.
  describe '.search' do
    # Closed, so the index holds its messages: a message is indexed with the session, when that is saved.
    let(:session) do
      create(:'chat/session', chat: topic, state: 'closed', user: other_agent, name: 'Ocarina lesson').tap do |session|
        create(:'chat/message', chat_session: session, content: 'My ocarina squeaks', created_by_id: nil)
        session.tag_add('escalation', 1)
      end
    end

    let(:results) { Chat::Session.search(current_user: agent, query:) }

    before do
      Setting.set('chat', true)
      session
    end

    context 'without search index' do
      context 'with a term matching the name' do
        let(:query) { 'ocarina' }

        it 'finds the session' do
          expect(results).to eq([session])
        end
      end

      context 'with a term matching the state' do
        let(:query) { 'closed' }

        it 'finds the session' do
          expect(results).to eq([session])
        end
      end

      context 'with a term matching a message' do
        let(:query) { 'squeaks' }

        it 'finds nothing, as the old UI' do
          expect(results).to be_empty
        end
      end

      context 'with a term matching a tag' do
        let(:query) { 'escalation' }

        it 'finds nothing, as the old UI' do
          expect(results).to be_empty
        end
      end
    end

    context 'with search index', searchindex: true do
      before { searchindex_model_reload([Chat::Session]) }

      context 'with a term matching the name' do
        let(:query) { 'ocarina' }

        it 'finds the session' do
          expect(results).to eq([session])
        end
      end

      context 'with a term matching a message' do
        let(:query) { 'squeaks' }

        it 'finds the session' do
          expect(results).to eq([session])
        end
      end

      context 'with a term matching a tag' do
        let(:query) { 'escalation' }

        it 'finds the session' do
          expect(results).to eq([session])
        end
      end

      context 'with a term matching the topic' do
        let(:query) { 'Support' }

        it 'finds the session' do
          expect(results).to eq([session])
        end
      end

      context 'with a term matching the agent who handled it' do
        let(:query) { 'Beispiel' }

        it 'finds the session' do
          expect(results).to eq([session])
        end
      end
    end
  end

  # The columns of the detailed search, which has the search sort by them.
  describe '.search sorted' do
    let(:bassoon)   { create(:'chat/session', chat: topic, state: 'waiting', name: 'Bassoon lesson', created_at: 2.days.ago) }
    let(:accordion) { create(:'chat/session', chat: topic, state: 'closed', name: 'Accordion lesson', created_at: 1.day.ago) }
    let(:cello)     { create(:'chat/session', chat: topic, state: 'running', name: 'Cello lesson', created_at: 3.days.ago) }

    let(:expected_orders) do
      {
        'id'         => [bassoon, accordion, cello],
        'name'       => [accordion, bassoon, cello],
        'state'      => [accordion, cello, bassoon],
        'created_at' => [cello, bassoon, accordion],
      }
    end

    def sorted_by(column)
      Chat::Session.search(current_user: agent, query: 'lesson', sort_by: [column], order_by: ['asc'])
    end

    before do
      Setting.set('chat', true)
      [bassoon, accordion, cello]
    end

    shared_examples 'sorting by every column' do
      %w[id name state created_at].each do |column|
        it "sorts by #{column}" do
          expect(sorted_by(column)).to eq(expected_orders[column])
        end
      end
    end

    context 'without search index' do
      it_behaves_like 'sorting by every column'
    end

    context 'with search index', searchindex: true do
      before { searchindex_model_reload([Chat::Session]) }

      it_behaves_like 'sorting by every column'
    end
  end
end
