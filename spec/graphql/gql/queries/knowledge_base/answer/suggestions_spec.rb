# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::KnowledgeBase::Answer::Suggestions, current_user_id: 1, type: :graphql do
  include KnowledgeBaseRichTextHelper

  context 'when searching' do
    let(:agent)    { create(:agent) }
    let(:customer) { create(:customer) }

    let(:knowledge_base_answer) { create(:knowledge_base_answer, :published, :with_video, :with_image, :with_attachment) }
    let(:knowledge_base_answer_translation) { knowledge_base_answer.translation }

    let(:query) do
      <<~QUERY
        query knowledgeBaseAnswerSuggestions($query: String!) {
          knowledgeBaseAnswerSuggestions(query: $query) {
            id
            title
            categoryTreeTranslation {
              id
              title
            }
            content {
              body
              bodyPrepared
              hasAttachments
            }
          }
        }
      QUERY
    end

    let(:variables) { { query: search_query } }

    before do
      gql.execute(query, variables: variables)
    end

    context 'with authenticated session', authenticated_as: :agent do
      let(:search_query)         { knowledge_base_answer_translation.title[0..2] }
      let(:category_translation) { knowledge_base_answer.category.translation_preferred(knowledge_base_answer_translation.kb_locale) }

      let(:expected_result) do
        [
          {
            'id'                      => Gql::ZammadSchema.id_from_object(knowledge_base_answer_translation),
            'title'                   => knowledge_base_answer_translation.title,
            'categoryTreeTranslation' => [
              {
                'id'    => Gql::ZammadSchema.id_from_object(category_translation),
                'title' => category_translation.title,
              },
            ],
            'content'                 => {
              'body'           => knowledge_base_answer_translation.content.body,
              'bodyPrepared'   => prepare_rich_text(knowledge_base_answer_translation.content.body_with_urls),
              'hasAttachments' => true,
            },
          }
        ]
      end

      it 'has data' do
        expect(gql.result.data).to eq(expected_result)
      end

      context 'with no results' do
        let(:search_query) { 'foo' }

        it 'has no data' do
          expect(gql.result.data).to be_empty
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      let(:search_query) { knowledge_base_answer_translation.title[0..2] }

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
