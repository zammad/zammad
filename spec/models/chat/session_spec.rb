# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Chat::Session, type: :model do

  describe '.search_index_attribute_lookup' do
    subject(:chat_session) { create(:'chat/session', user: chat_user, chat: chat) }

    let(:chat) { create(:chat) }
    let(:chat_user) { create(:agent) }

    it 'verify message attribute' do
      expect(chat_session.search_index_attribute_lookup['messages']).to eq []
    end

    it 'verify user attribute' do
      expect(chat_session.search_index_attribute_lookup['user']['id']).to eq chat_user.id
    end

    it 'verify chat attribute' do
      expect(chat_session.search_index_attribute_lookup['chat']['name']).to eq chat.name
    end

  end
end
