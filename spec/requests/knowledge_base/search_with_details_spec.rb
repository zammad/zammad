# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base search with details', searchindex: true, type: :request do
  include_context 'basic Knowledge Base'

  before do
    published_answer

    if defined?(answer_body)
      published_answer.translations.first.content.update!(body: answer_body)
    end

    searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
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
    let(:alternative_translation) { create(:'knowledge_base/answer/translation', title: search_phrase, kb_locale: alternative_locale, answer: published_answer) }

    before do
      alternative_translation
      searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
    end

    it 'returns answer in locale without category translation' do
      post endpoint, params: { query: search_phrase }

      expect(json_response['details'][0]['id']).to be alternative_translation.id
    end
  end

  context 'when parent category translation to one of locales is missing' do
    let(:search_phrase) { 'search_phrase' }
    let(:child_category)             { create(:'knowledge_base/category', parent: category) }
    let(:child_category_translation) { create(:'knowledge_base/category/translation', title: search_phrase, kb_locale: alternative_locale, category: child_category) }

    before do
      child_category_translation
      searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
    end

    it 'returns category in locale without category translation', authenticated_as: -> { create(:admin) } do
      post endpoint, params: { query: search_phrase, include_subtitle: true }
      expect(json_response['details'][0]['subtitle']).to eq category.translation_to(primary_locale).title
    end
  end

  context 'when answer tree is long' do
    let(:category1)        { create(:'knowledge_base/category') }
    let(:category2)        { create(:'knowledge_base/category', parent: category1) }
    let(:category3)        { create(:'knowledge_base/category', parent: category2) }
    let(:answer_cut_tree)  { create(:knowledge_base_answer, :published, :with_attachment, category: category3) }
    let(:category4)        { create(:'knowledge_base/category') }
    let(:category5)        { create(:'knowledge_base/category', parent: category4) }
    let(:answer_full_tree) { create(:knowledge_base_answer, :published, :with_attachment, category: category5) }

    before do
      answer_cut_tree && answer_full_tree
      searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
    end

    it 'returns category with cut tree', authenticated_as: -> { create(:admin) } do
      post endpoint, params: { query: answer_cut_tree.translations.first.title, include_subtitle: true }
      expect(json_response['details'][0]['subtitle']).to eq("#{category1.translations.first.title} > .. > #{category3.translations.first.title}")
    end

    it 'returns category with full tree', authenticated_as: -> { create(:admin) } do
      post endpoint, params: { query: answer_full_tree.translations.first.title, include_subtitle: true }
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
      searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
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

  # https://github.com/zammad/zammad/issues/5902
  context 'when preparing body for use in preview' do
    let(:answer_body) { 'This is a test answer.<br>It contains line breaks.<div></div><div>It should be <b>handled</b> properly.</div>' }

    context 'with ElasticSearch' do
      context 'when no highlighting' do
        it 'does not merge words around line breaks' do
          post endpoint, params: { query: published_answer.translations.first.title }

          expect(json_response['details'][0]['body'])
            .to include('This is a test answer. It contains line breaks. It should be handled properly.')
        end
      end

      context 'when body has highlighting' do
        it 'does not merge words around line breaks' do
          post endpoint, params: { query: 'test answer' }

          expect(json_response['details'][0]['body'])
            .to include('This is a <em>test</em> <em>answer</em>. It contains line breaks. It should be handled properly.')
        end
      end
    end

    context 'with SQL fallback', searchindex: false do
      it 'does not merge words around line breaks' do
        post endpoint, params: { query: published_answer.translations.first.title }

        expect(json_response['details'][0]['body'])
          .to include('This is a test answer. It contains line breaks. It should be handled properly.')
      end
    end
  end

  context 'when sorting' do
    let(:answers) do
      Array.new(3) do |nth|
        travel nth.seconds do
          create(:knowledge_base_answer, :published, :with_attachment,
                 category:               category,
                 translation_attributes: { title: "#{search_phrase} #{nth}" })
        end
      end
    end

    let(:search_phrase) { 'paging test' }

    before do |example|
      answers

      travel(3.hours) { answers[1].translations.first.touch }

      next if !example.metadata[:searchindex]

      searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
    end

    shared_examples 'test sorting' do
      it 'sorts answers from most up-to-date to oldest' do
        post endpoint, params: { query: search_phrase }

        returned_ids = json_response['details'].pluck('id')
        expected_ids = [answers[1], answers[2], answers[0]].map { |elem| elem.translations.first.id }

        expect(returned_ids).to eq expected_ids
      end
    end

    context 'with elasticsearch' do
      include_examples 'test sorting'
    end

    context 'with no elasticsearch', searchindex: false do
      include_examples 'test sorting'
    end
  end

  context 'when scoping' do
    let(:search_phrase) { 'scoping test' }

    before do |example|
      published_answer_in_other_category
      published_answer_in_subcategory

      [published_answer, published_answer_in_other_category, published_answer_in_subcategory].each do |elem|
        elem.translations.first.update!(title: "#{search_phrase} #{elem.id}")
      end

      next if !example.metadata[:searchindex]

      searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
    end

    shared_examples 'test scoping' do
      it 'finds answers only in the defined scope' do
        post endpoint, params: { query: search_phrase, scope_id: category.id, knowledge_base_id: knowledge_base.id }

        returned_ids = json_response['details'].pluck('id')

        expect(returned_ids).to contain_exactly(published_answer.translations.first.id, published_answer_in_subcategory.translations.first.id)
      end
    end

    context 'with elasticsearch' do
      include_examples 'test scoping'
    end

    context 'with no elasticsearch', searchindex: false do
      include_examples 'test scoping'
    end
  end
end
