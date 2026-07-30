# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::KnowledgeBase::Answers, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:query) do
    <<~GQL
      query knowledgeBaseAnswers($categoryId: ID!, $locale: String, $first: Int) {
        knowledgeBaseAnswers(categoryId: $categoryId, locale: $locale, first: $first) {
          edges { node { id title visibility translationMissing tags } }
          pageInfo { hasNextPage }
        }
      }
    GQL
  end
  let(:category_id) { gql.id(category) }
  let(:locale)      { nil }
  let(:first)       { nil }
  let(:variables)   { { categoryId: category_id, locale:, first: }.compact }

  before do
    published_answer
    internal_answer
    draft_answer
    archived_answer
    gql.execute(query, variables:)
  end

  context 'with an admin (editor)', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    it 'returns published, internal, draft and archived answers' do
      expect(gql.result.nodes.pluck('id'))
        .to contain_exactly(gql.id(published_answer), gql.id(internal_answer), gql.id(draft_answer), gql.id(archived_answer))
    end

    it 'color-codes answers by publication state', :aggregate_failures do
      by_id = gql.result.nodes.index_by { |node| node['id'] }

      expect(by_id[gql.id(published_answer)]).to include('visibility' => 'published')
      expect(by_id[gql.id(internal_answer)]).to include('visibility' => 'internal')
      expect(by_id[gql.id(draft_answer)]).to include('visibility' => 'draft')
      expect(by_id[gql.id(archived_answer)]).to include('visibility' => 'archived')
    end

    it 'resolves the answer title from its translation' do
      by_id = gql.result.nodes.index_by { |node| node['id'] }

      expect(by_id[gql.id(published_answer)]['title']).to eq(published_answer.translation_primary.title)
    end
  end

  context 'with an agent (reader)', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'returns internal and published answers' do
      expect(gql.result.nodes.pluck('id'))
        .to contain_exactly(gql.id(published_answer), gql.id(internal_answer))
    end
  end

  context 'with a customer (public)', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    it 'returns only published answers' do
      expect(gql.result.nodes.pluck('id')).to contain_exactly(gql.id(published_answer))
    end
  end

  context 'without authentication' do
    it 'is rejected' do
      expect(gql.result.error_type).to eq(Exceptions::NotAuthorized)
    end
  end

  # Listing answers is authorized with the same rule as browsing the category,
  #   so a user cannot reach (by URL) answers of a category hidden from them.
  context 'when the category is not browsable by the user' do
    let(:category_id) { gql.id(other_category) }

    before do
      internal_answer_in_other_category # other_category => internal-only
      gql.execute(query, variables:)
    end

    context 'with a customer (public)', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  # Mirrors the agent app: non-editors only see answers translated to the
  #   browsed locale, editors also see untranslated ones (title falls back).
  context 'with an answer not translated to the browsed locale' do
    let(:untranslated_answer) do
      create(:knowledge_base_answer, :internal, category: category, translation_attributes: { kb_locale: alternative_locale })
    end

    before do
      untranslated_answer
      gql.execute(query, variables:)
    end

    context 'with an agent (reader)', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      it 'hides the untranslated answer' do
        expect(gql.result.nodes.pluck('id')).not_to include(gql.id(untranslated_answer))
      end
    end

    context 'with an admin (editor)', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      it 'shows the untranslated answer' do
        expect(gql.result.nodes.pluck('id')).to include(gql.id(untranslated_answer))
      end
    end

    context 'with an admin (editor) browsing the alternative locale', authenticated_as: :admin do
      let(:admin)  { create(:admin) }
      let(:locale) { alternative_locale.system_locale.locale }

      it 'flags answers whose title falls back from a missing translation', :aggregate_failures do
        by_id = gql.result.nodes.index_by { |node| node['id'] }

        expect(by_id[gql.id(published_answer)]).to include('translationMissing' => true)
        expect(by_id[gql.id(untranslated_answer)]).to include('translationMissing' => false)
      end
    end
  end

  context 'with a tagged answer', authenticated_as: :admin do
    let(:admin) { create(:admin) }
    let(:by_id) { gql.result.nodes.index_by { |node| node['id'] } }

    before do
      published_answer_with_tag
      gql.execute(query, variables:)
    end

    it 'exposes the assigned tags' do
      expect(by_id[gql.id(published_answer_with_tag)]).to include('tags' => [published_answer_tag_name])
    end

    it 'exposes an empty list for an answer without tags' do
      expect(by_id[gql.id(published_answer)]).to include('tags' => [])
    end
  end

  context 'when the knowledge base is inactive', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    before do
      knowledge_base.update!(active: false)
      gql.execute(query, variables:)
    end

    it 'exposes no answers from the inactive knowledge base' do
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
  end

  context 'when many answers are listed', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    def translation_query_count
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        queries << payload[:sql] if payload[:sql].include?('knowledge_base_answer_translations')
      end
      gql.execute(query, variables:)
      queries.size
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    # Titles and translation-missing flags are resolved from the eager-loaded
    #   translations, so the number of translation queries must stay constant as
    #   the answer list grows (an editor is used so untranslated answers are shown
    #   and per-answer authorization does not itself touch translations).
    it 'resolves titles in a constant number of translation queries' do
      baseline = translation_query_count

      create_list(:knowledge_base_answer, 5, :published, category:)

      expect(translation_query_count).to eq(baseline)
    end
  end
end
