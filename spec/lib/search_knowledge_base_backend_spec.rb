# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SearchKnowledgeBaseBackend do
  include_context 'basic Knowledge Base'

  let(:instance) { described_class.new options }
  let(:user)     { create(:admin) }

  let(:options) do
    {
      knowledge_base: knowledge_base,
      locale:         primary_locale,
      scope:          nil
    }
  end

  def handle_elasticsearch(enabled)
    if enabled
      searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
    else
      Setting.set('es_url', nil)
    end
  end

  context 'with ES', searchindex: true do
    describe '#search' do
      context 'when highlight enabled' do
        let(:options) do
          {
            knowledge_base:    knowledge_base,
            locale:            primary_locale,
            scope:             nil,
            highlight_enabled: true
          }
        end

        before do
          published_answer
          handle_elasticsearch(true)
        end

        # https://github.com/zammad/zammad/issues/3070
        it 'lists item with an attachment' do
          expect(instance.search('Hello World', user: user)).to be_present
        end
      end
    end
  end

  context 'with paging' do
    let(:answers) do
      Array.new(20) do |nth|
        create(:knowledge_base_answer, :published, :with_attachment, category: category, translation_attributes: { title: "#{search_phrase} #{nth}" })
      end
    end

    let(:search_phrase) { 'paging test' }

    let(:options) do
      {
        knowledge_base: knowledge_base,
        locale:         primary_locale,
        scope:          nil,
        order_by:       { id: :desc }
      }
    end

    shared_examples 'verify paging' do |elasticsearch:|
      context "when elastic search is #{elasticsearch}", searchindex: elasticsearch do
        before do
          answers

          handle_elasticsearch(elasticsearch)
        end

        it 'first page is first 5 answers' do
          results = instance.search(search_phrase, user: user, pagination: build(:pagination, params: { page: 1, per_page: 5 }))

          first_5 = answers.reverse.slice(0, 5)

          expect(results.pluck(:id)).to eq first_5.map { |answer| answer.translations.first.id }
        end

        it 'second page is next 5 answers' do
          results = instance.search(search_phrase, user: user, pagination: build(:pagination, params: { page: 2, per_page: 5 }))

          next_5 = answers.reverse.slice(5, 5)

          expect(results.pluck(:id)).to eq next_5.map { |answer| answer.translations.first.id }
        end

        it 'last page may be partial' do
          results = instance.search(search_phrase, user: user, pagination: build(:pagination, params: { page: 4, per_page: 6 }))

          last_page = answers.reverse.slice(18, 6)

          expect(results.pluck(:id)).to eq last_page.map { |answer| answer.translations.first.id }
        end

        it '5th page is empty' do
          results = instance.search(search_phrase, user: user, pagination: build(:pagination, params: { page: 5, per_page: 5 }))

          expect(results).to be_blank
        end
      end
    end

    include_examples 'verify paging', elasticsearch: true
    include_examples 'verify paging', elasticsearch: false
  end

  context 'with successful API response' do
    before do
      published_answer
    end

    shared_examples 'verify response' do |elasticsearch:|
      it "ID is an Integer when ES=#{elasticsearch}", searchindex: elasticsearch do
        handle_elasticsearch(elasticsearch)

        first_result = instance.search(published_answer.translations.first.title, user: user).first
        expect(first_result[:id]).to be_a(Integer)
      end
    end

    include_examples 'verify response', elasticsearch: true
    include_examples 'verify response', elasticsearch: false
  end

  context 'with user trait and object state' do
    def expected_visibility_instance(ui_identifier)
      options = {
        knowledge_base: knowledge_base,
        locale:         primary_locale,
        scope:          nil,
        flavor:         ui_identifier
      }

      described_class.new options
    end

    shared_examples 'verify given search backend' do |permissions:, ui:, elasticsearch:|
      is_visible = permissions == :all || permissions == ui
      prefix     = is_visible ? 'lists' : 'does not list'

      it "#{prefix} in #{ui} interface when ES=#{elasticsearch}", searchindex: elasticsearch do
        instance = expected_visibility_instance ui
        object

        handle_elasticsearch(elasticsearch)

        expect(instance.search(object.translations.first.title, user: user)).to is_visible ? be_present : be_blank
      end
    end

    shared_examples 'verify given permissions' do |scope:, trait:, admin:, agent:|
      context "with #{trait} #{scope}" do
        let(:object) { create("knowledge_base_#{scope}", trait, knowledge_base: knowledge_base) }

        include_examples 'verify given user', user_id: :admin, permissions: admin
        include_examples 'verify given user', user_id: :agent, permissions: agent
      end
    end

    shared_examples 'verify given user' do |user_id:, permissions:|
      context "with #{user_id}" do
        let(:user) { create(user_id) }

        include_examples 'verify given search backend', permissions: permissions, ui: :agent, elasticsearch: true
        include_examples 'verify given search backend', permissions: permissions, ui: :agent, elasticsearch: false

        include_examples 'verify given search backend', permissions: permissions, ui: :public, elasticsearch: true
        include_examples 'verify given search backend', permissions: permissions, ui: :public, elasticsearch: false
      end
    end

    include_examples 'verify given permissions', scope: :answer, trait: :published, admin: :all, agent: :all
    include_examples 'verify given permissions', scope: :answer, trait: :internal,  admin: :all, agent: :agent
    include_examples 'verify given permissions', scope: :answer, trait: :draft,     admin: :all, agent: :none
    include_examples 'verify given permissions', scope: :answer, trait: :archived,  admin: :all, agent: :none

    include_examples 'verify given permissions', scope: :category, trait: :empty,                admin: :all, agent: :none
    include_examples 'verify given permissions', scope: :category, trait: :containing_published, admin: :all, agent: :all
    include_examples 'verify given permissions', scope: :category, trait: :containing_internal,  admin: :all, agent: :agent
    include_examples 'verify given permissions', scope: :category, trait: :containing_draft,     admin: :all, agent: :none
    include_examples 'verify given permissions', scope: :category, trait: :containing_archived,  admin: :all, agent: :none
  end
end
