# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# No service behind this mutation — deleting is a single `destroy!` on the loaded record, so this
#   spec covers the deletion itself along with the GraphQL surface around it.
RSpec.describe Gql::Mutations::KnowledgeBase::Answer::Delete, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:editor)      { create(:user, roles: [editor_role]) }

  let(:query) do
    <<~QUERY
      mutation knowledgeBaseAnswerDelete($answerId: ID!) {
        knowledgeBaseAnswerDelete(answerId: $answerId) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  # `:with_attachment` comes from the shared context, so the cascade below has something to remove.
  let(:record)    { published_answer }
  let(:variables) { { answerId: gql.id(record) } }

  before do
    setup if defined?(setup)
    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    it 'reports success' do
      expect(gql.result.data).to include('success' => true)
    end

    it 'deletes the answer' do
      expect(KnowledgeBase::Answer).not_to exist(id: record.id)
    end

    # Unlike a category, an answer has no restricted dependents: everything below it goes with it,
    #   so there is no "empty it first" step and no refusal path to cover.
    it 'deletes its translations' do
      expect(KnowledgeBase::Answer::Translation).not_to exist(answer_id: record.id)
    end

    it 'deletes its attachments' do
      expect(Store.list(object: 'KnowledgeBase::Answer', o_id: record.id)).to be_empty
    end
  end

  # Only an active knowledge base is editable — the legacy admin dialog is what activates it.
  context 'when the knowledge base is inactive', authenticated_as: :editor do
    let(:setup) { knowledge_base.update!(active: false) }

    it 'raises an error' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end

    it 'deletes nothing' do
      expect(KnowledgeBase::Answer).to exist(id: record.id)
    end

    # The counterpart of the deletion case above: the same lookup finds the attachment as long as
    #   the answer is still there, so that assertion cannot pass just because it looks in the wrong
    #   place.
    it 'keeps its attachments' do
      expect(Store.list(object: 'KnowledgeBase::Answer', o_id: record.id)).not_to be_empty
    end
  end

  context 'with a granular editor of one subtree' do
    let(:granular_role)   { create(:role, permission_names: 'knowledge_base.editor') }
    let(:granular_editor) { create(:user, roles: [granular_role]) }

    # Editor on the subcategory, only reader on the knowledge base — and therefore on the category
    #   holding the answer. KnowledgeBase::AnswerPolicy#destroy? asks about the answer's own
    #   category, so editor access to a sibling subtree is not enough.
    let(:setup) do
      create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
      create(:knowledge_base_permission, permissionable: subcategory, role: granular_role, access: 'editor')
    end

    context 'when deleting an answer outside the subtree they are editor of', authenticated_as: :granular_editor do
      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end

      it 'deletes nothing' do
        expect(KnowledgeBase::Answer).to exist(id: record.id)
      end
    end

    context 'when deleting an answer inside the subtree they are editor of', authenticated_as: :granular_editor do
      let(:record) { published_answer_in_subcategory }

      it 'reports success' do
        expect(gql.result.data).to include('success' => true)
      end

      it 'deletes the answer' do
        expect(KnowledgeBase::Answer).not_to exist(id: record.id)
      end
    end
  end

  context 'with a reader', authenticated_as: :reader do
    let(:reader) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

    it 'raises an error' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end

    it 'deletes nothing' do
      expect(KnowledgeBase::Answer).to exist(id: record.id)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
