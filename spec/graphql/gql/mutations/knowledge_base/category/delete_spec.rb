# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# No service behind this mutation — deleting is a single `destroy!` on the loaded record, so this
#   spec covers the deletion itself along with the GraphQL surface around it.
RSpec.describe Gql::Mutations::KnowledgeBase::Category::Delete, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:editor)      { create(:user, roles: [editor_role]) }

  let(:query) do
    <<~QUERY
      mutation knowledgeBaseCategoryDelete($categoryId: ID!) {
        knowledgeBaseCategoryDelete(categoryId: $categoryId) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:record)    { category }
  let(:variables) { { categoryId: gql.id(record) } }

  before do
    setup if defined?(setup)
    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    it 'reports success' do
      expect(gql.result.data).to include('success' => true)
    end

    it 'deletes an empty category' do
      expect(KnowledgeBase::Category).not_to exist(id: record.id)
    end

    # Both associations are `dependent: :restrict_with_exception`: emptying the category first is a
    #   deliberate, explicit step rather than a recursive delete. The database error that enforces
    #   it is turned into something the user can act on, worded like the legacy delete dialog.
    context 'with a subcategory' do
      let(:setup) { subcategory }

      it 'returns a user error' do
        expect(gql.result.data['errors'])
          .to include(include('message' => 'Delete all child categories and answers, then try again.'))
      end

      it 'deletes nothing' do
        expect(KnowledgeBase::Category).to exist(id: record.id)
      end
    end

    context 'with an answer' do
      let(:setup) { draft_answer }

      it 'returns a user error' do
        expect(gql.result.data['errors'])
          .to include(include('message' => 'Delete all child categories and answers, then try again.'))
      end
    end
  end

  # Only an active knowledge base is editable — the legacy admin dialog is what activates it.
  context 'when the knowledge base is inactive', authenticated_as: :editor do
    let(:setup) { knowledge_base.update!(active: false) }

    it 'raises an error' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end

    it 'deletes nothing' do
      expect(KnowledgeBase::Category).to exist(id: record.id)
    end
  end

  context 'with a granular editor of one subtree' do
    let(:granular_role)   { create(:role, permission_names: 'knowledge_base.editor') }
    let(:granular_editor) { create(:user, roles: [granular_role]) }

    # Editor on the subcategory, only reader on its parent. Deleting a category changes what its
    #   parent contains, so KnowledgeBase::CategoryPolicy#destroy? asks about the parent — editor
    #   access to the category itself is not enough.
    let(:setup) do
      create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
      create(:knowledge_base_permission, permissionable: subcategory, role: granular_role, access: 'editor')
    end

    context 'when deleting a category below the one they are editor of', authenticated_as: :granular_editor do
      let(:record) { subcategory }

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
