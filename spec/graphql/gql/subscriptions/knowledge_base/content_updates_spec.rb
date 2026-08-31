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

  # The preload in #update: the policy asks every category on the broadcast whether its knowledge
  #   base is active, and the categories arrive deserialized, so without it that is a SELECT per
  #   category — for every subscriber, on every broadcast. Unlike a request, a broadcast has no
  #   query cache to absorb the repeats: they are all round trips.
  context 'with several categories on the broadcast', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    def knowledge_base_query_count(categories)
      queries = 0

      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        next if payload[:cached] || payload[:name] == 'SCHEMA'

        queries += 1 if payload[:sql].include?('"knowledge_bases"')
      end

      described_class.trigger({ categories: })

      queries
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    # The affected categories a change carries are the changed category and its ancestors, so a
    #   deeper nesting is what puts more of them on one broadcast.
    def nested_category_path(depth)
      deepest = depth.times.reduce(nil) { |parent, _| create(:knowledge_base_category, knowledge_base: knowledge_base, parent: parent) }

      deepest.self_with_parents
    end

    it 'looks the knowledge base up a constant number of times as the category path grows' do
      shallow = nested_category_path(2)
      deep    = nested_category_path(5)

      baseline = knowledge_base_query_count(shallow)

      expect(knowledge_base_query_count(deep)).to eq(baseline)
    end
  end

  # Deactivating is the one change subscribers cannot notice any other way: the browse queries
  #   answer not-found from then on, so they have to be told to ask again.
  context 'when the knowledge base is deactivated', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    before do
      mock_channel.mock_broadcasted_messages.clear

      knowledge_base.update!(active: false)
    end

    it 'still pings, with no knowledge base left to hand out', :aggregate_failures do
      expect(mock_channel.mock_broadcasted_messages.first&.dig(:result, 'data', 'knowledgeBaseContentUpdates'))
        .to eq('knowledgeBase' => nil, 'affectedCategoryIds' => [])
      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'errors')).to be_nil
    end
  end
end
