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

  describe '.active_chats_by_user_id' do
    let(:agent)        { create(:agent) }
    let(:chat_session) { create(:'chat/session', chat: create(:chat), state: 'running', user: agent) }

    before { chat_session.tag_add('vip', 1) }

    it 'includes the tags of the session' do
      expect(described_class.active_chats_by_user_id(agent.id)).to contain_exactly(hash_including('id' => chat_session.id, 'tags' => ['vip']))
    end
  end
end
