# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::KnowledgeBase::ContentUpdates, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:mock_channel) { build_mock_channel }
  let(:subscription) do
    <<~GQL
      subscription knowledgeBaseContentUpdates {
        knowledgeBaseContentUpdates {
          knowledgeBase { id }
          affectedCategoryIds
        }
      }
    GQL
  end

  before do
    knowledge_base
    gql.execute(subscription, context: { channel: mock_channel })
  end

  context 'with a customer (no knowledge base permission)', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    it 'subscribes without initial data' do
      expect(gql.result.data).to eq('knowledgeBase' => nil, 'affectedCategoryIds' => nil)
    end

    it 'pings subscribers with the active knowledge base when content changes' do
      create(:knowledge_base_answer, :published, category: category)

      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'knowledgeBaseContentUpdates', 'knowledgeBase', 'id'))
        .to eq(gql.id(knowledge_base))
    end

    it 'reports the affected category path so the client can decide whether to refetch' do
      subcategory
      mock_channel.mock_broadcasted_messages.clear

      create(:knowledge_base_answer, :published, category: subcategory)

      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'knowledgeBaseContentUpdates', 'affectedCategoryIds'))
        .to eq([gql.id(subcategory), gql.id(category)])
    end
  end
end
