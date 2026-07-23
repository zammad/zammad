# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::KnowledgeBaseAnswer, authenticated_as: :agent, type: :graphql do
  include_context 'basic Knowledge Base'

  context 'when searching for knowledge base answers' do
    let(:agent) { create(:agent) }

    let(:answer) do
      create(:knowledge_base_answer, :published, category:, translation_attributes: { title: 'Findable Answer Title' })
    end
    let(:answer_translation) { answer.translation }
    let(:category_translation) { category.translation_preferred(answer_translation.kb_locale) }

    let(:query) do
      <<~QUERY
        query autocompleteSearchKnowledgeBaseAnswer($input: AutocompleteSearchKnowledgeBaseAnswerInput!) {
          autocompleteSearchKnowledgeBaseAnswer(input: $input) {
            value
            label
            heading
            visibility
          }
        }
      QUERY
    end
    let(:variables) do
      { input: { query: query_string, limit:, exceptAnswerIds: except_answer_ids } }
    end
    # Without Elasticsearch the search falls back to an exact (case-insensitive)
    #   title match, so the test searches for the full title.
    let(:query_string)      { 'Findable Answer Title' }
    let(:limit)             { nil }
    let(:except_answer_ids) { nil }

    before do
      answer
      gql.execute(query, variables:)
    end

    it 'returns the matching answer translation' do
      expect(gql.result.data).to include(
        'value'      => Gql::ZammadSchema.id_from_object(answer_translation),
        'label'      => answer_translation.title,
        'heading'    => category_translation.title,
        'visibility' => 'published',
      )
    end

    context 'when the category has no translation in the answer locale' do
      # The answer is translated to the alternative locale, but the category only has its
      # primary-locale translation, so the heading must fall back to it (translation_preferred).
      let(:answer) do
        create(:knowledge_base_answer, :published, category:,
                                                   translation_attributes: { title: 'Findable Answer Title', kb_locale: alternative_locale })
      end

      it 'falls back to the primary category translation title for the heading' do
        expect(gql.result.data.first).to include(
          'heading' => category.translation_preferred(alternative_locale).title,
        )
      end
    end

    context 'when excluding already-linked answers' do
      let(:except_answer_ids) { [Gql::ZammadSchema.id_from_object(answer_translation)] }

      it 'filters out the excluded answer translation' do
        expect(gql.result.data).to be_empty
      end
    end

    context 'when sending an empty search string' do
      let(:query_string) { '   ' }

      it 'returns nothing' do
        expect(gql.result.data).to be_empty
      end
    end

    context 'without knowledge base permission', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'returns nothing' do
        expect(gql.result.data).to be_empty
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
