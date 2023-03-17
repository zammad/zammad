# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base Locale Search', type: :system do
  include_context 'basic Knowledge Base'

  let!(:answer_for_search) { create(:knowledge_base_answer, category: category, translation_attributes: { title: 'A example title' }) }

  context 'when search query is directly used inside the url' do
    let(:search_query) { nil }

    before do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/search/#{search_query}"
    end

    shared_examples 'check search result' do
      it 'answer exists in search result' do
        within :active_content do
          expect(page).to have_css('.knowledge-base-main .section', text: answer_for_search.translations.first.title)
        end
      end
    end

    context 'when search query is a single word' do
      let(:search_query) { 'Example' }

      include_examples 'check search result'
    end

    context 'when search query has encoded characters' do
      let(:search_query) { 'A%20Example' }

      include_examples 'check search result'
    end
  end
end
