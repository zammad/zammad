# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base search with details', type: :request, searchindex: true do
  include_context 'basic Knowledge Base'

  before do
    published_answer
    searchindex_model_reload([::KnowledgeBase::Translation, ::KnowledgeBase::Category::Translation, ::KnowledgeBase::Answer::Translation])
  end

  let(:endpoint) { '/api/v1/knowledge_bases/search' }

  context 'ensure details ID type matches ES ID type' do
    it 'for answers' do
      post endpoint, params: { query: published_answer.translations.first.title }

      expect(json_response['details'][0]['id']).to be_a Integer
    end

    it 'for categories' do
      post endpoint, params: { query: category.translations.first.title }

      expect(json_response['details'][0]['id']).to be_a Integer
    end

    it 'for knowledge base' do
      post endpoint, params: { query: knowledge_base.translations.first.title }

      expect(json_response['details'][0]['id']).to be_a Integer
    end
  end

  context 'when category translation to one of locales is missing' do
    let(:search_phrase) { 'search_phrase' }
    let(:alternative_translation) { create('knowledge_base/answer/translation', title: search_phrase, kb_locale: alternative_locale, answer: published_answer) }

    before do
      alternative_translation
      searchindex_model_reload([::KnowledgeBase::Translation, ::KnowledgeBase::Category::Translation, ::KnowledgeBase::Answer::Translation])
    end

    it 'returns answer in locale without category translation' do
      post endpoint, params: { query: search_phrase }

      expect(json_response['details'][0]['id']).to be alternative_translation.id
    end
  end

  context 'when parent category translation to one of locales is missing' do
    let(:search_phrase) { 'search_phrase' }
    let(:child_category)             { create('knowledge_base/category', parent: category) }
    let(:child_category_translation) { create('knowledge_base/category/translation', title: search_phrase, kb_locale: alternative_locale, category: child_category) }

    before do
      child_category_translation
      searchindex_model_reload([::KnowledgeBase::Translation, ::KnowledgeBase::Category::Translation, ::KnowledgeBase::Answer::Translation])
    end

    it 'returns category in locale without category translation', authenticated_as: -> { create(:admin) } do
      post endpoint, params: { query: search_phrase }
      expect(json_response['details'][0]['subtitle']).to eq category.translation_to(primary_locale).title
    end
  end

  context 'when answer tree is long' do
    let(:category1) { create('knowledge_base/category') }
    let(:category2)        { create('knowledge_base/category', parent: category1) }
    let(:category3)        { create('knowledge_base/category', parent: category2) }
    let(:answer_cut_tree)  { create(:knowledge_base_answer, :published, :with_attachment, category: category3) }
    let(:category4)        { create('knowledge_base/category') }
    let(:category5)        { create('knowledge_base/category', parent: category4) }
    let(:answer_full_tree) { create(:knowledge_base_answer, :published, :with_attachment, category: category5) }

    before do
      answer_cut_tree && answer_full_tree
      searchindex_model_reload([::KnowledgeBase::Translation, ::KnowledgeBase::Category::Translation, ::KnowledgeBase::Answer::Translation])
    end

    it 'returns category with cut tree', authenticated_as: -> { create(:admin) } do
      post endpoint, params: { query: answer_cut_tree.translations.first.title }
      expect(json_response['details'][0]['subtitle']).to eq("#{category1.translations.first.title} > .. > #{category3.translations.first.title}")
    end

    it 'returns category with full tree', authenticated_as: -> { create(:admin) } do
      post endpoint, params: { query: answer_full_tree.translations.first.title }
      expect(json_response['details'][0]['subtitle']).to eq("#{category4.translations.first.title} > #{category5.translations.first.title}")
    end
  end

  context 'when using include_locale parameter' do
    context 'when no multiple locales exists' do
      it 'no locale added to title' do
        post endpoint, params: { query: published_answer.translations.first.title, include_locale: true }
        expect(json_response['details'][0]['title']).to not_include('(EN-US)')
      end
    end

    context 'when multiple locales exists' do
      before do
        # Create a alternative knowledge base locale.
        alternative_locale
      end

      it 'locale added to title' do
        post endpoint, params: { query: published_answer.translations.first.title, include_locale: true }
        expect(json_response['details'][0]['title']).to include('(EN-US)')
      end
    end
  end

  context 'when using paging' do
    let(:answers) do
      Array.new(20) do |nth|
        create(:knowledge_base_answer, :published, :with_attachment, category: category, translation_attributes: { title: "#{search_phrase} #{nth}" })
      end
    end

    let(:search_phrase) { 'paging test' }

    before do
      answers
      searchindex_model_reload([::KnowledgeBase::Translation, ::KnowledgeBase::Category::Translation, ::KnowledgeBase::Answer::Translation])
    end

    it 'returns success' do
      post endpoint, params: { query: search_phrase, per_page: 10, page: 0 }

      expect(response).to have_http_status(:ok)
    end

    it 'returns defined amount of items' do
      post endpoint, params: { query: search_phrase, per_page: 7, page: 0 }

      expect(json_response['result'].count).to be 7
    end
  end
end
