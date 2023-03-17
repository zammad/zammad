# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase public answers', type: :request do
  include_context 'basic Knowledge Base'

  describe '#show' do
    context 'when visitor is a guest' do
      it 'returns OK for published answer' do
        get help_answer_path(locale_name, category, published_answer)
        expect(response).to have_http_status :ok
      end

      it 'returns NOT FOUND for draft answer' do
        get help_answer_path(locale_name, category, draft_answer)
        expect(response).to have_http_status :not_found
      end
    end

    context 'when visitor is an editor' do
      before do
        published_answer && draft_answer
        authenticated_as(create(:admin), via: :browser)
      end

      it 'returns OK for published answer' do
        get help_answer_path(locale_name, category, published_answer)
        expect(response).to have_http_status :ok
      end

      it 'returns OK for draft answer' do
        get help_answer_path(locale_name, category, draft_answer)
        expect(response).to have_http_status :ok
      end
    end
  end

  describe '#render_alternative' do
    context 'when a translation is available' do
      before { create(:knowledge_base_translation, kb_locale: alternative_locale) }

      it 'returns OK for published answer' do
        get help_answer_path(alternative_locale.system_locale.locale, category, published_answer)
        expect(response).to have_http_status :ok
      end

      it 'returns NOT FOUND for draft answer' do
        get help_answer_path(alternative_locale.system_locale.locale, category, draft_answer)
        expect(response).to have_http_status :not_found
      end

      # https://github.com/zammad/zammad/issues/3931
      context 'when the category has been updated' do
        let(:new_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }

        it 'returns NOT FOUND for published answer if old category is used' do
          published_answer.update! category_id: new_category.id

          get help_answer_path(alternative_locale.system_locale.locale, category, published_answer)
          expect(response).to have_http_status :not_found
        end

        it 'returns OK for published answer if new category is used' do
          published_answer.update! category_id: new_category.id

          get help_answer_path(alternative_locale.system_locale.locale, new_category, published_answer)
          expect(response).to have_http_status :ok
        end
      end
    end
  end
end
