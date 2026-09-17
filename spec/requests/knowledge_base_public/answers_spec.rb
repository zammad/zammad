# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase public answers', type: :request do
  include_context 'basic Knowledge Base'

  before do
    # Skip asset generation.
    allow_any_instance_of(ActionView::Base).to receive(:compute_asset_path).and_return('')
  end

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

    context 'when knowledge base is inactive' do
      before do
        knowledge_base.update! active: false
      end

      # https://github.com/zammad/zammad/issues/3888
      it 'returns route not found error' do
        get help_answer_path(locale_name, category, published_answer)
        expect(response.body).to include(CGI.escapeHTML("This page doesn't exist."))
      end

      # https://github.com/zammad/zammad/issues/6338
      context 'when visitor is an editor' do
        before do
          authenticated_as(create(:admin), via: :browser)
        end

        it 'returns route not found error for published answer' do
          get help_answer_path(locale_name, category, published_answer)
          expect(response.body).to include(CGI.escapeHTML("This page doesn't exist."))
        end

        it 'returns route not found error for draft answer' do
          get help_answer_path(locale_name, category, draft_answer)
          expect(response.body).to include(CGI.escapeHTML("This page doesn't exist."))
        end

        it 'returns route not found error for the start page' do
          get help_root_path(locale: locale_name)
          expect(response.body).to include(CGI.escapeHTML("This page doesn't exist."))
        end
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

  # The previous/next links under an answer walk the whole tree, and have to walk it in the order the
  #   listing they were reached from renders — so a node that is not sorted manually moves them too.
  describe 'previous/next navigation' do
    def answer_titled(title)
      create(:knowledge_base_answer, :published, category:, translation_attributes: { title: "SortingCanary #{title}" })
    end

    # The titles the two links point at, as the rendered page offers them.
    def adjacent_titles(answer, locale: locale_name)
      get help_answer_path(locale, category, answer)

      %w[previous next].map { |direction| response.parsed_body.at_css(".article-nav-adjacent-#{direction} a")&.attr('title') }
    end

    # Created against their alphabetical order, so the hand-arranged order disagrees with it.
    let!(:zulu)  { answer_titled('Zulu') }
    let!(:mike)  { answer_titled('Mike') }
    let!(:alpha) { answer_titled('Alpha') }

    it 'walks the hand-arranged order in the manual mode' do
      expect(adjacent_titles(mike)).to eq([zulu.translation.title, alpha.translation.title])
    end

    context 'with the alphabetical mode' do
      before { category.update!(answer_sorting_mode: 'alphabetical') }

      it 'walks the order the listing renders' do
        expect(adjacent_titles(mike)).to eq([alpha.translation.title, zulu.translation.title])
      end
    end

    # https://github.com/zammad/zammad/issues/6367
    context 'with a second locale' do
      let(:alternative_locale_name) { alternative_locale.system_locale.locale }

      let!(:category_lt) { create(:knowledge_base_category_translation, category:, kb_locale: alternative_locale, title: 'Kategorija') }
      let!(:zulu_lt)     { create(:knowledge_base_answer_translation, answer: zulu, kb_locale: alternative_locale, title: 'Zulu lietuviskai') }
      let!(:alpha_lt)    { create(:knowledge_base_answer_translation, answer: alpha, kb_locale: alternative_locale, title: 'Alpha lietuviskai') }

      before do
        create(:knowledge_base_translation, kb_locale: alternative_locale)
        create(:knowledge_base_answer_translation, answer: mike, kb_locale: alternative_locale, title: 'Mike lietuviskai')
      end

      it 'offers the links in the browsed locale' do
        expect(adjacent_titles(mike, locale: alternative_locale_name)).to eq([zulu_lt.title, alpha_lt.title])
      end

      it 'links through the category in the browsed locale' do
        get help_answer_path(alternative_locale_name, category, mike)

        expect(response.parsed_body.at_css('.article-nav-adjacent-next a').attr('href')).to include(category_lt.to_param)
      end
    end
  end
end
