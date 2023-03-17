# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase permissions', authenticated_as: :current_user, type: :request do
  include_context 'basic Knowledge Base'

  let(:current_user) { create(:admin) }
  let(:role_admin)   { Role.find_by(name: 'Admin') }
  let(:role_agent)   { Role.find_by(name: 'Agent') }

  let(:initial_permissions) do
    {
      permissions: {
        role_admin.id => 'editor',
        role_agent.id => 'none'
      }
    }
  end

  let(:update_permissions) do
    {
      permissions: {
        role_admin.id => 'editor',
        role_agent.id => 'reader'
      }
    }
  end

  let(:expected_response) do
    {
      'inherited'    => be_empty,
      'permissions'  => be_empty,
      'roles_reader' => match_array([{ 'id' => role_agent.id, 'name' => 'Agent' }]),
      'roles_editor' => match_array([{ 'id' => role_admin.id, 'name' => 'Admin' }])
    }
  end

  let(:expected_response_permissions) do
    permissions = [
      { 'access' => 'editor', 'id' => KnowledgeBase::Permission.first.id, 'role_id' => role_admin.id },
      { 'access' => 'none', 'id' => KnowledgeBase::Permission.last.id, 'role_id' => role_agent.id }
    ]

    expected_response.merge({ 'permissions' => match_array(permissions) })
  end

  shared_examples 'verify permissions' do
    describe '#show' do
      it 'returns success' do
        get url

        expect(response).to have_http_status(:ok)
      end

      it 'returns correct response' do
        get url

        expect(json_response).to include(expected_response)
      end

      context 'with initial permissions' do
        before do
          KnowledgeBase::PermissionsUpdate.new(object, current_user).update_using_params!(initial_permissions)
        end

        it 'returns correct response' do
          get url

          expect(json_response).to include(expected_response_permissions)
        end
      end

      context 'when a role has both KB permissions' do
        before do
          role_agent.permission_grant('knowledge_base.editor')
        end

        it 'ensures that same role is not returned twice' do
          get url

          expect(json_response['roles_reader'].intersection(json_response['roles_editor']))
            .to be_empty
        end

        it 'ensures that ambiguous role is returned as editor' do
          get url

          editor_includes_agent = json_response['roles_editor'].find { |elem| elem['id'] == role_agent.id }

          expect(editor_includes_agent).to be_truthy
        end
      end
    end

    describe '#update' do
      before do
        put url, params: params
      end

      let(:params) do
        {
          permissions_dialog: update_permissions
        }
      end

      it 'returns success' do
        put url, params: params
        expect(response).to have_http_status(:ok)
      end

      it 'saves update' do
        put url, params: params
        expect(KnowledgeBase::Permission.last.access).to eq 'reader'
      end
    end
  end

  context 'with a category' do
    let(:object) { category }
    let(:url) { "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{category.id}/permissions" }

    include_examples 'verify permissions'
  end

  context 'with a knowledge base' do
    let(:object) { knowledge_base }
    let(:url) { "/api/v1/knowledge_bases/#{knowledge_base.id}/permissions" }

    include_examples 'verify permissions'
  end
end
