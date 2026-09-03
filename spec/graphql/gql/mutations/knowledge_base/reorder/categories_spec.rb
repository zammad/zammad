# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What is stored, and which orders are refused, is Service::KnowledgeBase::Reorder::Categories'
#   business and is covered in spec/services/service/knowledge_base/reorder/categories_spec.rb. This
#   covers the mutation around it: the category it loads and gates, and what it renders back.
RSpec.describe Gql::Mutations::KnowledgeBase::Reorder::Categories, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:editor)      { create(:user, roles: [editor_role]) }

  let(:first)  { create(:knowledge_base_category, knowledge_base:, parent: category, position: 0) }
  let(:second) { create(:knowledge_base_category, knowledge_base:, parent: category, position: 1) }

  let(:query) do
    <<~QUERY
      mutation knowledgeBaseReorderCategories($parentCategoryId: ID!, $sortingMode: EnumKnowledgeBaseSortingMode!, $categoryIds: [ID!]) {
        knowledgeBaseReorderCategories(parentCategoryId: $parentCategoryId, sortingMode: $sortingMode, categoryIds: $categoryIds) {
          category {
            id
            title
            categorySortingMode
            answerSortingMode
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:parent)       { category }
  let(:sorting_mode) { 'alphabetical' }
  let(:category_ids) { nil }
  let(:variables)    { { parentCategoryId: gql.id(parent), sortingMode: sorting_mode, categoryIds: category_ids }.compact }

  before do
    first && second

    setup if defined?(setup)
    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    it 'returns the parent category with the stored mode' do
      expect(gql.result.data['category']).to include(
        'id'                  => gql.id(category),
        'categorySortingMode' => 'alphabetical',
      )
    end

    # The category's two lists have a mode each, so the one this mutation does not order is left as
    #   it was — the combination a single column could not express.
    it 'leaves the mode of that category\'s answers alone' do
      expect(gql.result.data.dig('category', 'answerSortingMode')).to eq('manual')
    end

    # No locale is asked of the caller, so the payload is rendered in the current user's preferred
    #   one — here the only one there is.
    it 'renders the category in the preferred locale' do
      expect(gql.result.data.dig('category', 'title')).to eq(category.translation_to(primary_locale).title)
    end

    context 'with a hand-made order' do
      let(:sorting_mode) { 'manual' }
      let(:category_ids) { [gql.id(second), gql.id(first)] }

      it 'hands the submitted order to the service, in the order it was sent' do
        expect([first, second].map { |record| record.reload.position }).to eq([1, 0])
      end
    end

    context 'with a hand-made order against an automatic mode' do
      let(:category_ids) { [gql.id(second), gql.id(first)] }

      it 'returns a user error', :aggregate_failures do
        expect(gql.result.data.dig('errors', 0, 'message')).to include('sorting mode is manual')
        expect(gql.result.data['category']).to be_nil
      end
    end

    context 'without a parent category' do
      let(:variables) { { sortingMode: sorting_mode } }

      it 'is refused by the schema' do
        expect(gql.result.error_message).to include('parentCategoryId')
      end
    end
  end

  context 'with a granular editor of one subtree' do
    let(:granular_role)   { create(:role, permission_names: 'knowledge_base.editor') }
    let(:granular_editor) { create(:user, roles: [granular_role]) }

    let(:setup) do
      create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
      create(:knowledge_base_permission, permissionable: category, role: granular_role, access: 'editor')
    end

    context 'with a category they may edit', authenticated_as: :granular_editor do
      it 'stores the mode' do
        expect(gql.result.data.dig('category', 'categorySortingMode')).to eq('alphabetical')
      end
    end

    # Gated on the way in, by the argument that loads the parent.
    context 'with a category they only read', authenticated_as: :granular_editor do
      let(:parent) { other_category }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'with a reader', authenticated_as: :reader do
    let(:reader) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

    it 'raises an error' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
