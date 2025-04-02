# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase answer', authenticated_as: :editor, type: :request do
  let(:editor) { create(:agent) }

  include_context 'basic Knowledge Base'

  describe '#show' do
    let(:published_answer_new_translation)   { create(:knowledge_base_answer_translation, answer: published_answer, kb_locale: alternative_locale) }
    let(:published_answer_first_translation) { published_answer.translations.first }

    before do
      published_answer
      draft_answer
      published_answer_new_translation

      get "/api/v1/knowledge_bases/#{knowledge_base.id}/answers/#{published_answer.id}?include_contents=#{include_contents}", as: :json
    end

    context 'when include_contents is not present' do
      let(:include_contents) { nil }

      it 'returns answer' do
        expect(json_response['assets']).to include_assets_of(published_answer)
      end

      it 'does not return contents' do
        expect(json_response['assets']).not_to include_assets_of(KnowledgeBase::Answer::Translation::Content.all)
      end
    end

    context 'when include_contents is present' do
      let(:include_contents) { published_answer_first_translation.content.id }

      it 'returns answer' do
        expect(json_response['assets']).to include_assets_of(published_answer)
      end

      it 'returns requested contents' do
        expect(json_response['assets']).to include_assets_of(published_answer_first_translation.content)
      end

      it 'does not return other contents' do
        expect(json_response['assets']).not_to include_assets_of(KnowledgeBase::Answer::Translation::Content.all - [published_answer_first_translation.content])
      end
    end

    context 'when include_contents is present as comma-separated list' do
      let(:include_contents) { published_answer.translations.map(&:content_id).join(',') }

      it 'returns answer' do
        expect(json_response['assets']).to include_assets_of(published_answer)
      end

      it 'returns all requested contents' do
        expect(json_response['assets']).to include_assets_of(published_answer.translations.map(&:content))
      end

      it 'does not return other contents' do
        expect(json_response['assets']).not_to include_assets_of(draft_answer.translations.map(&:content))
      end
    end

    context 'when include_contents includes ID of another answer content' do
      let(:include_contents) { draft_answer.translations.first.content.id }

      it 'returns answer' do
        expect(json_response['assets']).to include_assets_of(published_answer)
      end

      it 'does not return mismatching contents' do
        expect(json_response['assets']).not_to include_assets_of(draft_answer.translations.first.content)
      end
    end

    context 'when include_contents is invalid value' do
      let(:include_contents) { ',' }

      it 'returns answer' do
        expect(json_response['assets']).to include_assets_of(published_answer)
      end

      it 'does not return any contents' do
        expect(json_response['assets']).not_to include_assets_of(KnowledgeBase::Answer::Translation::Content.all)
      end
    end
  end
end
