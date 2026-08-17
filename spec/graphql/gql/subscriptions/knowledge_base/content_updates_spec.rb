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

  let(:broadcasted_affected_category_ids) do
    mock_channel.mock_broadcasted_messages.first&.dig(:result, 'data', 'knowledgeBaseContentUpdates', 'affectedCategoryIds')
  end

  before do
    knowledge_base
    gql.execute(subscription, context: { channel: mock_channel })
  end

  context 'without knowledge base permission', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    # Used to raise Exceptions::Forbidden, while the browse queries served the
    #   same user — browsing published content needs no permission.
    it 'subscribes without initial data' do
      expect(gql.result.data).to eq('knowledgeBase' => nil, 'affectedCategoryIds' => nil)
    end

    it 'pings with the affected category path once the content is publicly visible' do
      subcategory
      mock_channel.mock_broadcasted_messages.clear

      create(:knowledge_base_answer, :published, category: subcategory)

      expect(broadcasted_affected_category_ids).to eq([gql.id(subcategory), gql.id(category)])
    end

    it 'sends no update for a change confined to categories without public content' do
      other_category
      mock_channel.mock_broadcasted_messages.clear

      create(:knowledge_base_answer, :internal, category: other_category)

      expect(mock_channel.mock_broadcasted_messages).to be_empty
    end

    it 'pings on a knowledge-base-wide change, which carries no categories to filter' do
      mock_channel.mock_broadcasted_messages.clear

      knowledge_base.translation_primary.update!(title: 'Renamed Knowledge Base')

      expect(broadcasted_affected_category_ids).to eq([])
    end
  end

  context 'with knowledge base permission (reader)', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    # The gate is KnowledgeBase::CategoryPolicy, not the content-based
    #   Category#visible_to_user?, which would drop this ping.
    it 'pings with a newly created category that holds no content yet' do
      mock_channel.mock_broadcasted_messages.clear

      new_category = create(:knowledge_base_category, knowledge_base: knowledge_base)

      expect(broadcasted_affected_category_ids).to eq([gql.id(new_category)])
    end
  end

  context 'with granular permissions', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    before do
      create(:knowledge_base_permission, permissionable: other_category, role: agent.roles.first, access: 'none')
      mock_channel.mock_broadcasted_messages.clear
    end

    it 'sends no update for a change in a category the role has no access to' do
      create(:knowledge_base_answer, :internal, category: other_category)

      expect(mock_channel.mock_broadcasted_messages).to be_empty
    end
  end

  context 'with knowledge base permission (editor)', authenticated_as: :agent do
    let(:agent) { create(:agent, roles: [create(:role, permission_names: %w[knowledge_base.editor])]) }

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

      expect(broadcasted_affected_category_ids).to eq([gql.id(subcategory), gql.id(category)])
    end
  end
end
