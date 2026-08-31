# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBase::Answer::Translation, '.search', current_user_id: -> { user.id }, type: :model do
  describe '.search' do
    context 'when using granular search' do
      let(:user)    { create(:user, role_ids: [role1.id]) }
      let(:role1)   { create(:role, permission_names: ['knowledge_base.editor']) }
      let(:kb)      { create(:knowledge_base) }
      let(:cat1)    { create(:knowledge_base_category, knowledge_base: kb) }
      let(:cat2)    { create(:knowledge_base_category, knowledge_base: kb) }
      let(:answer1) { create(:knowledge_base_answer, :draft, knowledge_base: kb, category: cat1, translation_attributes: { title: title1 }) }
      let(:answer2) { create(:knowledge_base_answer, :draft, knowledge_base: kb, category: cat2, translation_attributes: { title: title1 }) }
      let(:title)   { Faker::Company.name }
      let(:title1)  { "#{title} 1" }
      let(:title2)  { "#{title} 2" }

      before do
        answer1 && answer2

        KnowledgeBase::PermissionsUpdate.new(kb).update! role1 => 'reader'
        KnowledgeBase::PermissionsUpdate.new(cat1).update! role1 => 'editor'
        KnowledgeBase::PermissionsUpdate.new(cat2).update! role1 => 'reader'
      end

      shared_examples 'returns results according to permissions' do
        it 'returns correct answer' do
          results = described_class.search({ query:, current_user: user, full: true })
          expect(results).to contain_exactly(answer1.translations.first)
        end
      end

      context 'when using ElasticSearch', searchindex: true do
        let(:query) { title }

        before do
          searchindex_model_reload([described_class])
        end

        it_behaves_like 'returns results according to permissions'
      end

      context 'when using SQL fallback', searchindex: false do
        let(:query) { "#{title}%" }

        it_behaves_like 'returns results according to permissions'
      end
    end

  end

  describe '.search_preferences' do
    let(:user) { create(:user, roles: [create(:role, permission_names: ['knowledge_base.editor'])]) }

    before { knowledge_base }

    context 'with an active knowledge base' do
      let(:knowledge_base) { create(:knowledge_base) }

      it 'offers the answers to the global search' do
        expect(described_class.search_preferences(user)).to include(prio: 1209)
      end
    end

    # A deactivated knowledge base contributes no searchable content, so with only that one around
    #   the global search does not ask for its answers at all.
    #   https://github.com/zammad/zammad/issues/6338
    context 'with an inactive knowledge base' do
      let(:knowledge_base) { create(:knowledge_base, active: false) }

      it 'is not searched' do
        expect(described_class.search_preferences(user)).to be(false)
      end
    end

    # An agent has 'knowledge_base.reader' through the default role, so this takes a user who has no
    #   knowledge base permission at all.
    context 'without any knowledge base permission' do
      let(:knowledge_base) { create(:knowledge_base) }
      let(:user)           { create(:customer) }

      it 'is not searched' do
        expect(described_class.search_preferences(user)).to be(false)
      end
    end
  end
end
