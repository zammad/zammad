# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBase::InternalAssets do
  include_context 'basic Knowledge Base' do
    before do
      draft_answer
      internal_answer
      published_answer
    end
  end

  describe '#collect_assets' do
    subject(:assets) { described_class.new(user).collect_assets }

    context 'when for KB editor' do
      let(:user) { create(:user, roles: Role.where(name: 'Admin')) }

      it 'returns assets for all KB objects' do
        expect(assets).to include_assets_of(knowledge_base, category, draft_answer, internal_answer, published_answer)
      end

      context 'when has editor permission' do
        before do
          KnowledgeBase::PermissionsUpdate.new(category).update! user.roles.first => 'editor'
        end

        it 'returns assets for all KB objects' do
          expect(assets).to include_assets_of(knowledge_base, category, draft_answer, internal_answer, published_answer)
        end
      end

      context 'when has reader permission' do
        before do
          KnowledgeBase::PermissionsUpdate.new(category).update! user.roles.first => 'reader'
        end

        it 'returns assets for internally visible KB objects' do
          expect(assets)
            .to include_assets_of(knowledge_base, category, internal_answer, published_answer)
            .and not_include_assets_of(draft_answer)
        end
      end

      context 'when has none permission' do
        before do
          KnowledgeBase::PermissionsUpdate.new(category).update! user.roles.first => 'none'
        end

        it 'does not return assets for internally visible KB objects' do
          published_answer.destroy # make sure public item does not make category visible

          expect(assets)
            .to  include_assets_of(knowledge_base)
            .and not_include_assets_of(category, draft_answer, internal_answer, published_answer)
        end

        it 'returns assets for published answer and it\'s category' do
          expect(assets)
            .to  include_assets_of(knowledge_base, category, published_answer)
            .and not_include_assets_of(draft_answer, internal_answer)
        end
      end
    end

    context 'when for agent' do
      let(:user) { create(:agent) }

      it 'returns assets for all KB objects' do
        expect(assets)
          .to include_assets_of(knowledge_base, category, internal_answer, published_answer)
          .and not_include_assets_of(draft_answer)
      end
    end

    context 'when for customer' do
      let(:user) { create(:customer) }

      it 'returns assets for all KB objects' do
        expect(assets)
          .to  include_assets_of(knowledge_base)
          .and not_include_assets_of(category, draft_answer, internal_answer, published_answer)
      end
    end

    context 'when filtering by categories' do
      subject(:assets) { described_class.new(user, categories_filter: other_category).collect_assets }

      before { published_answer_in_other_category }

      let(:user) { create(:agent) }

      it 'returns assets for all KB objects' do
        expect(assets)
          .to include_assets_of(knowledge_base, other_category, published_answer_in_other_category)
          .and not_include_assets_of(draft_answer, category, internal_answer, published_answer)
      end
    end
  end
end
