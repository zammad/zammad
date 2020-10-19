require 'rails_helper'

RSpec.describe 'Knowledge Base search with details', type: :request, searchindex: true do
  include_context 'basic Knowledge Base'

  before do
    configure_elasticsearch(required: true, rebuild: true) do
      published_answer
    end
  end

  let(:endpoint) { '/api/v1/knowledge_bases/search' }

  context 'ensure details ID type matches ES ID type' do
    it 'for answers' do
      post endpoint, params: { query: published_answer.translations.first.title }

      expect(json_response['details'][0]['id']).to be_a_kind_of Integer
    end

    it 'for categories' do
      post endpoint, params: { query: category.translations.first.title }

      expect(json_response['details'][0]['id']).to be_a_kind_of Integer
    end

    it 'for knowledge base' do
      post endpoint, params: { query: knowledge_base.translations.first.title }

      expect(json_response['details'][0]['id']).to be_a_kind_of Integer
    end
  end

  context 'when category translation to one of locales is missing' do
    let(:search_phrase) { 'search_phrase' }
    let(:alternative_translation) { create('knowledge_base/answer/translation', title: search_phrase, kb_locale: alternative_locale, answer: published_answer) }

    before do
      alternative_translation
      rebuild_searchindex
    end

    it 'returns answer in locale without category translation' do
      post endpoint, params: { query: search_phrase }

      expect(json_response['details'][0]['id']).to be alternative_translation.id
    end
  end

  context 'when parent category translation to one of locales is missing' do
    let(:search_phrase)  { 'search_phrase' }
    let(:child_category) { create('knowledge_base/category', parent: category) }
    let(:child_category_translation) { create('knowledge_base/category/translation', title: search_phrase, kb_locale: alternative_locale, category: child_category) }

    before do
      child_category_translation && rebuild_searchindex
    end

    it 'returns category in locale without category translation', authenticated_as: -> { create(:admin) } do
      post endpoint, params: { query: search_phrase }
      expect(json_response['details'][0]['subtitle']).to eq category.translation_to(primary_locale).title
    end
  end
end
