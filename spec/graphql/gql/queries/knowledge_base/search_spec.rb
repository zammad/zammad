# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::KnowledgeBase::Search, :searchindex, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:gql_query) do
    <<~GQL
      query knowledgeBaseSearch($query: String!, $categoryId: ID, $locale: String, $first: Int) {
        knowledgeBaseSearch(query: $query, categoryId: $categoryId, locale: $locale, first: $first) {
          totalCount
          edges {
            node {
              item {
                ... on KnowledgeBaseAnswer { id translation { title } }
                ... on KnowledgeBaseCategory { id translation { title } visibility }
              }
              titlePreview { text highlight }
              bodyPreview { text highlight }
              categoryPath { id title }
            }
          }
          pageInfo { endCursor hasNextPage }
        }
      }
    GQL
  end

  let(:search)      { 'ocarina' }
  let(:category_id) { nil }
  let(:locale)      { nil }
  let(:first)       { nil }
  let(:variables)   { { query: search, categoryId: category_id, locale:, first: }.compact }

  let(:published_ocarina) do
    create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Ocarina tuning' })
  end

  let(:internal_ocarina) do
    create(:knowledge_base_answer, :internal, category: category, translation_attributes: { title: 'Ocarina repair' })
  end

  let(:draft_ocarina) do
    create(:knowledge_base_answer, :draft, category: category, translation_attributes: { title: 'Ocarina draft' })
  end

  let(:subcategory_ocarina) do
    create(:knowledge_base_answer, :published, category: subcategory, translation_attributes: { title: 'Ocarina cleaning' })
  end

  let(:other_category_ocarina) do
    create(:knowledge_base_answer, :published, category: other_category, translation_attributes: { title: 'Ocarina storage' })
  end

  let(:ocarina_category) do
    create(:knowledge_base_category, knowledge_base: knowledge_base, parent: category).tap do |elem|
      elem.translations.first.update!(title: 'Ocarina department')
    end
  end

  # Its answer is titled so that it does not match the search itself — the category is the hit
  #   here, and its published answer only gives the category something to be visible from.
  let(:ocarina_category_with_content) do
    create(:knowledge_base_category, knowledge_base: knowledge_base, parent: category).tap do |elem|
      elem.translations.first.update!(title: 'Ocarina archive')
      create(:knowledge_base_answer, :published, category: elem, translation_attributes: { title: 'Woodwind storage' })
    end
  end

  # Overridden where extra hits are needed in the index, which the shared setup below builds.
  let(:extra_ocarina_categories) { [] }

  def item_ids
    gql.result.nodes.map { |node| node.dig('item', 'id') }
  end

  def node_for(record)
    gql.result.nodes.find { |node| node.dig('item', 'id') == gql.id(record) }
  end

  before do
    published_ocarina
    internal_ocarina
    draft_ocarina
    subcategory_ocarina
    other_category_ocarina
    ocarina_category
    ocarina_category_with_content
    extra_ocarina_categories
    searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
    gql.execute(gql_query, variables:)
  end

  context 'with an admin (editor)', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    it 'finds answers of every publication state' do
      expect(item_ids).to include(gql.id(published_ocarina), gql.id(internal_ocarina), gql.id(draft_ocarina))
    end

    it 'finds categories alongside answers' do
      expect(item_ids).to include(gql.id(ocarina_category))
    end

    it 'never returns the knowledge base node itself' do
      expect(gql.result.nodes.pluck('item')).to all(include('translation'))
    end

    it 'marks the matched run of the title' do
      segments = node_for(published_ocarina)['titlePreview']

      expect(segments.select { |segment| segment['highlight'] }.pluck('text')).to eq(['Ocarina'])
    end

    it 'keeps the whole title across the segments' do
      expect(node_for(published_ocarina)['titlePreview'].pluck('text').join).to eq('Ocarina tuning')
    end

    it 'previews the body even when only the title matched' do
      expect(node_for(published_ocarina)['bodyPreview']).to be_present
    end

    it 'leaves a category without a body preview' do
      expect(node_for(ocarina_category)['bodyPreview']).to be_empty
    end

    it 'reports the category path root first' do
      expect(node_for(subcategory_ocarina)['categoryPath'].pluck('title'))
        .to eq([category, subcategory].map { |elem| elem.translation_primary.title })
    end

    it 'ids each category path segment for linking the breadcrumb' do
      expect(node_for(subcategory_ocarina)['categoryPath'].pluck('id'))
        .to eq([category, subcategory].map { |elem| gql.id(elem) })
    end

    it 'counts every hit the user may see' do
      expect(gql.result.data['totalCount']).to eq(gql.result.nodes.size)
    end

    it 'reports the subtree visibility of a category hit' do
      expect(node_for(ocarina_category_with_content)['item']).to include('visibility' => 'published')
    end

    it 'reads a category hit with no content as draft' do
      expect(node_for(ocarina_category)['item']).to include('visibility' => 'draft')
    end
  end

  # The visibility of a category hit is batched in Service::KnowledgeBase::Search; without it,
  #   CategoryType#visibility walks the subtree with a recursive query once per publication state,
  #   for every category on the page.
  context 'when many categories match', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    let(:extra_ocarina_categories) do
      create_list(:knowledge_base_category, 5, knowledge_base:, parent: category).each_with_index.map do |elem, index|
        elem.tap { elem.translations.first.update!(title: "Ocarina shelf #{index}") }
      end
    end

    def answer_queries
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        queries << payload[:sql] if payload[:sql].include?('knowledge_base_answers')
      end
      gql.execute(gql_query, variables:)
      queries.size
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    it 'keeps the answer queries constant as more categories are hit', :aggregate_failures do
      baseline = answer_queries
      baseline_ids = item_ids

      create_list(:knowledge_base_category, 5, knowledge_base:, parent: category).each_with_index do |elem, index|
        elem.translations.first.update!(title: "Ocarina crate #{index}")
      end
      searchindex_model_reload([KnowledgeBase::Category::Translation])

      count = answer_queries

      expect(item_ids.size).to be > baseline_ids.size
      expect(count).to eq(baseline)
    end
  end

  context 'when scoped to a category', authenticated_as: :admin do
    let(:admin)       { create(:admin) }
    let(:category_id) { gql.id(category) }

    it 'includes hits from the category and its subcategories' do
      expect(item_ids).to include(gql.id(published_ocarina), gql.id(subcategory_ocarina))
    end

    it 'excludes hits from a sibling subtree' do
      expect(item_ids).not_to include(gql.id(other_category_ocarina))
    end
  end

  context 'with an agent (reader)', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'returns internal and published answers' do
      expect(item_ids).to include(gql.id(published_ocarina), gql.id(internal_ocarina))
    end

    it 'hides drafts' do
      expect(item_ids).not_to include(gql.id(draft_ocarina))
    end
  end

  context 'with a customer (public)', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    it 'returns only published answers' do
      expect(item_ids).to include(gql.id(published_ocarina))
    end

    it 'hides internal answers' do
      expect(item_ids).not_to include(gql.id(internal_ocarina))
    end
  end

  context 'without authentication' do
    it 'is rejected' do
      expect(gql.result.error_type).to eq(Exceptions::NotAuthorized)
    end
  end

  # Scoping is authorized with the same rule as browsing the category, so a user cannot search
  #   inside (by URL) a category that is hidden from them.
  context 'when the scope category is not browsable by the user', authenticated_as: :customer do
    let(:customer)    { create(:customer) }
    let(:category_id) { gql.id(other_category) }

    before do
      other_category.answers.each { |answer| answer.update!(published_at: nil, internal_at: Time.zone.now) }
      gql.execute(gql_query, variables:)
    end

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when the knowledge base is inactive', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    before do
      knowledge_base.update!(active: false)
      gql.execute(gql_query, variables:)
    end

    it 'exposes nothing' do
      expect(gql.result.data['edges']).to be_empty
    end
  end

  context 'with a blank query', authenticated_as: :admin do
    let(:admin)  { create(:admin) }
    let(:search) { '' }

    it 'returns nothing, so entering the page searches for nothing' do
      expect(gql.result.data['edges']).to be_empty
    end
  end

  context 'with pagination', authenticated_as: :admin do
    let(:admin) { create(:admin) }
    let(:first) { 1 }

    it 'limits the page and reports that more pages exist', :aggregate_failures do
      expect(gql.result.data['edges'].size).to eq(1)
      expect(gql.result.data['pageInfo']).to include('hasNextPage' => true)
    end

    it 'still reports the full total, not the page size' do
      expect(gql.result.data['totalCount']).to be > 1
    end
  end
end
