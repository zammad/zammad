# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::KnowledgeBaseType, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:query) do
    <<~GQL
      query knowledgeBase {
        knowledgeBase {
          policy {
            update
          }
        }
      }
    GQL
  end

  before do
    knowledge_base
    gql.execute(query)
  end

  # Gates both "edit knowledge base" and "add category" at the root, since a top level category is
  #   created under the knowledge base itself.
  context 'with an editor', authenticated_as: :editor do
    let(:editor) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.editor')]) }

    it 'allows updating the knowledge base' do
      expect(gql.result.data['policy']).to include('update' => true)
    end
  end

  context 'with a reader', authenticated_as: :reader do
    let(:reader) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

    it 'does not allow updating the knowledge base' do
      expect(gql.result.data['policy']).to include('update' => false)
    end
  end
end
