# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Administering the knowledge base is `admin.knowledge_base` throughout. It used not to be for
#   three of these endpoints: Controllers::KnowledgeBase::ManageControllerPolicy inherited
#   `permit! %i[create update destroy], to: 'knowledge_base.editor'` from a shared base policy, and
#   its own `default_permit!('admin.knowledge_base')` could not displace those keys, because
#   `default_permit!` assigns the Hash's default while `permit!` assigns keys - and a key always
#   wins. A content editor could create a knowledge base, rewrite every attribute of the existing
#   one and destroy it with all of its content. See zammad/coordination-security#153.
RSpec.describe 'KnowledgeBase manage authorization', type: :request do
  include_context 'basic Knowledge Base'

  let(:role) { create(:role, permission_names: [permission]) }
  let(:user) { create(:user, roles: [role]) }

  context 'when the user is a knowledge base editor without admin.knowledge_base', authenticated_as: :user do
    let(:permission) { 'knowledge_base.editor' }

    it 'holds the editor permission but not the administrative one', :aggregate_failures do
      expect(user.permissions?('knowledge_base.editor')).to be true
      expect(user.permissions?('admin.knowledge_base')).to be false
    end

    it 'refuses to create a knowledge base' do
      post '/api/v1/knowledge_bases/manage', params: { homepage_layout: 'grid' }, as: :json

      expect(response).to have_http_status(:forbidden)
    end

    # #params_for_permission is `params.permit!`, so an authorized update writes any attribute -
    #   `active`, which takes the public help site offline, and `custom_address`, which repoints
    #   it. Asserted on the record as well as on the status, because a refusal that still wrote
    #   would pass on the status alone.
    it 'refuses to update a knowledge base', :aggregate_failures do
      knowledge_base

      expect { put "/api/v1/knowledge_bases/manage/#{knowledge_base.id}", params: { active: false }, as: :json }
        .not_to change { knowledge_base.reload.active }

      expect(response).to have_http_status(:forbidden)
    end

    # #destroy is `full_destroy!` - the knowledge base and every category and answer under it.
    it 'refuses to destroy a knowledge base', :aggregate_failures do
      knowledge_base

      expect { delete "/api/v1/knowledge_bases/manage/#{knowledge_base.id}", as: :json }
        .not_to change { KnowledgeBase.exists?(knowledge_base.id) }

      expect(response).to have_http_status(:forbidden)
    end

    # These two always required `admin.knowledge_base`, which is what made the gap visible:
    #   switching the knowledge base off was refused while updating it - which can set `active` -
    #   was not.
    it 'refuses to deactivate a knowledge base' do
      knowledge_base

      patch "/api/v1/knowledge_bases/manage/#{knowledge_base.id}/deactivate", as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when the user is an administrator', authenticated_as: :user do
    let(:permission) { 'admin.knowledge_base' }

    it 'updates a knowledge base', :aggregate_failures do
      knowledge_base

      expect { put "/api/v1/knowledge_bases/manage/#{knowledge_base.id}", params: { active: false }, as: :json }
        .to change { knowledge_base.reload.active }.from(true).to(false)

      expect(response).to have_http_status(:ok)
    end

    it 'destroys a knowledge base', :aggregate_failures do
      knowledge_base

      expect { delete "/api/v1/knowledge_bases/manage/#{knowledge_base.id}", as: :json }
        .to change { KnowledgeBase.exists?(knowledge_base.id) }.from(true).to(false)

      expect(response).to have_http_status(:ok)
    end
  end
end
