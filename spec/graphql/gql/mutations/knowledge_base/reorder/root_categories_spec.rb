# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What is stored, and which orders are refused, is Service::KnowledgeBase::Reorder::Categories'
#   business and is covered in spec/services/service/knowledge_base/reorder/categories_spec.rb. This
#   covers the mutation around it: its permission gate, the arguments the schema accepts, how a
#   refusal reaches the client, and what it renders back.
RSpec.describe Gql::Mutations::KnowledgeBase::Reorder::RootCategories, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:editor)      { create(:user, roles: [editor_role]) }

  let(:first)  { create(:knowledge_base_category, knowledge_base:, position: 0) }
  let(:second) { create(:knowledge_base_category, knowledge_base:, position: 1) }

  let(:query) do
    <<~QUERY
      mutation knowledgeBaseReorderRootCategories($sortingMode: EnumKnowledgeBaseSortingMode!, $categoryIds: [ID!]) {
        knowledgeBaseReorderRootCategories(sortingMode: $sortingMode, categoryIds: $categoryIds) {
          knowledgeBase {
            id
            title
            categorySortingMode
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:sorting_mode) { 'alphabetical' }
  let(:category_ids) { nil }
  let(:variables)    { { sortingMode: sorting_mode, categoryIds: category_ids }.compact }

  before do
    first && second

    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    it 'returns the knowledge base with the stored mode' do
      expect(gql.result.data['knowledgeBase']).to include(
        'id'                  => gql.id(knowledge_base),
        'categorySortingMode' => 'alphabetical',
      )
    end

    # No locale is asked of the caller, so the payload is rendered in the current user's preferred
    #   one — here the only one there is.
    it 'renders the knowledge base in the preferred locale' do
      expect(gql.result.data.dig('knowledgeBase', 'title')).to eq(knowledge_base.translation_primary.title)
    end

    context 'with a hand-made order' do
      let(:sorting_mode) { 'manual' }
      let(:category_ids) { [gql.id(second), gql.id(first)] }

      it 'hands the submitted order to the service, in the order it was sent' do
        expect([first, second].map { |record| record.reload.position }).to eq([1, 0])
      end
    end

    # The service refuses an order that the mode it is stored against would never read back; the
    #   client gets it as a user error to show rather than as a failed request.
    context 'with a hand-made order against an automatic mode' do
      let(:category_ids) { [gql.id(second), gql.id(first)] }

      it 'returns a user error', :aggregate_failures do
        expect(gql.result.data.dig('errors', 0, 'message')).to include('sorting mode is manual')
        expect(gql.result.data['knowledgeBase']).to be_nil
      end
    end

    context 'with an incomplete order' do
      let(:sorting_mode) { 'manual' }
      let(:category_ids) { [gql.id(first)] }

      it 'returns a user error' do
        expect(gql.result.data.dig('errors', 0, 'message')).to include('all items in scope')
      end
    end

    # `manual` is the only mode that reads a stored order back, so it may not be armed without one —
    #   the client sends the order it is showing along with it.
    context 'with the manual mode and no order' do
      let(:sorting_mode) { 'manual' }
      let(:category_ids) { nil }

      it 'returns a user error', :aggregate_failures do
        expect(gql.result.data.dig('errors', 0, 'message')).to include('all items in scope')
        expect(gql.result.data['knowledgeBase']).to be_nil
      end
    end

    context 'with a mode the models cannot store' do
      let(:sorting_mode) { 'by_hand' }

      it 'is refused by the schema' do
        expect(gql.result.error_message).to include('Variable $sortingMode of type EnumKnowledgeBaseSortingMode! was provided invalid value')
      end
    end

    context 'without a mode' do
      let(:variables) { { categoryIds: [gql.id(first), gql.id(second)] } }

      it 'is refused by the schema' do
        expect(gql.result.error_message).to include('sortingMode')
      end
    end

    # `acts_as_list` is scoped to `parent`, so a category from further down the tree is not part of
    #   the list this mutation numbers — the scope check is what catches it, the schema cannot.
    context 'with a category that is not at the top level' do
      let(:sorting_mode) { 'manual' }
      let(:category_ids) { [gql.id(second), gql.id(first), gql.id(subcategory)] }

      it 'returns a user error' do
        expect(gql.result.data.dig('errors', 0, 'message')).to include('all items in scope')
      end
    end
  end

  # The top level belongs to the knowledge base, so ordering it needs editor access to the knowledge
  #   base itself — which a granular editor of one subtree does not have. No argument names the node
  #   here, so the service's own Pundit check is what refuses it.
  context 'with a granular editor of one subtree' do
    let(:granular_role)   { create(:role, permission_names: 'knowledge_base.editor') }
    let(:granular_editor) { create(:user, roles: [granular_role]) }

    let(:setup) do
      create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
      create(:knowledge_base_permission, permissionable: first, role: granular_role, access: 'editor')
    end

    before do
      setup

      gql.execute(query, variables:)
    end

    it 'raises an error', authenticated_as: :granular_editor do
      expect(gql.result.error_type).to eq(Pundit::NotAuthorizedError)
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
