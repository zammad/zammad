# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
end
