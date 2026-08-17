# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase categories reordering', authenticated_as: :current_user, type: :request do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: ['knowledge_base.editor']) }
  let(:editor)      { create(:user, roles: [editor_role]) }

  # Stock agents get knowledge_base.reader by default.
  let(:reader) { create(:agent) }

  def reorder
    patch url, params: { ordered_ids: reordered_ids }, as: :json
  end

  shared_examples 'an editor-only reorder endpoint' do
    context 'with knowledge_base.reader permissions' do
      let(:current_user) { reader }

      it 'is forbidden' do
        reorder

        expect(response).to have_http_status(:forbidden)
      end

      it 'does not reorder the records' do
        expect { reorder }.not_to change { current_order }
      end
    end

    context 'with knowledge_base.editor permissions' do
      let(:current_user) { editor }

      it 'returns success' do
        reorder

        expect(response).to have_http_status(:ok)
      end

      it 'reorders the records' do
        expect { reorder }.to change { current_order }.to(reordered_ids)
      end
    end
  end

  context 'when reordering root categories' do
    let!(:root_categories) { create_list(:knowledge_base_category, 2, knowledge_base: knowledge_base) }

    let(:url)           { "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/reorder_root_categories" }
    let(:reordered_ids) { root_categories.map(&:id).reverse }

    def current_order
      knowledge_base.categories.root.reorder(position: :asc).pluck(:id)
    end

    include_examples 'an editor-only reorder endpoint'
  end

  context 'when reordering categories' do
    let!(:subcategories) { create_list(:knowledge_base_category, 2, knowledge_base: knowledge_base, parent: category) }

    let(:url)           { "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{category.id}/reorder_categories" }
    let(:reordered_ids) { subcategories.map(&:id).reverse }

    def current_order
      category.children.reorder(position: :asc).pluck(:id)
    end

    include_examples 'an editor-only reorder endpoint'
  end

  context 'when reordering answers' do
    let!(:answers) { create_list(:knowledge_base_answer, 2, category: category) }

    let(:url)           { "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{category.id}/reorder_answers" }
    let(:reordered_ids) { answers.map(&:id).reverse }

    def current_order
      category.answers.reorder(position: :asc).pluck(:id)
    end

    include_examples 'an editor-only reorder endpoint'
  end

  # Both member routes resolve the category unscoped in the policy, so only the controller's
  #   scoped lookup keeps an editor of one knowledge base out of another one's categories.
  context 'when the category belongs to another knowledge base' do
    let(:other_knowledge_base) { create(:knowledge_base) }
    let(:current_user)         { editor }

    shared_examples 'a knowledge base scoped member route' do
      it 'is not found' do
        reorder

        expect(response).to have_http_status(:not_found)
      end

      it 'does not reorder the records' do
        expect { reorder }.not_to change { current_order }
      end
    end

    context 'when reordering categories' do
      let!(:subcategories) { create_list(:knowledge_base_category, 2, knowledge_base: knowledge_base, parent: category) }

      let(:url)           { "/api/v1/knowledge_bases/#{other_knowledge_base.id}/categories/#{category.id}/reorder_categories" }
      let(:reordered_ids) { subcategories.map(&:id).reverse }

      def current_order
        category.children.reorder(position: :asc).pluck(:id)
      end

      include_examples 'a knowledge base scoped member route'
    end

    context 'when reordering answers' do
      let!(:answers) { create_list(:knowledge_base_answer, 2, category: category) }

      let(:url)           { "/api/v1/knowledge_bases/#{other_knowledge_base.id}/categories/#{category.id}/reorder_answers" }
      let(:reordered_ids) { answers.map(&:id).reverse }

      def current_order
        category.answers.reorder(position: :asc).pluck(:id)
      end

      include_examples 'a knowledge base scoped member route'
    end
  end
end
