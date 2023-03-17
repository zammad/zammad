# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Shared Drafts Start API endpoints', authenticated_as: :agent, type: :request do

  let(:group_a) { create(:group, shared_drafts: true) }
  let(:group_b) { create(:group, shared_drafts: true) }
  let(:group_c) { create(:group, shared_drafts: false) }
  let(:group_d) { create(:group, shared_drafts: true) }

  let(:role_group_d) { create(:role, groups: [group_d]) }

  let(:draft_a) { create(:ticket_shared_draft_start, group: group_a) }
  let(:draft_b) { create(:ticket_shared_draft_start, group: group_b) }
  let(:draft_c) { create(:ticket_shared_draft_start, group: group_c) }
  let(:draft_d) { create(:ticket_shared_draft_start, group: group_d) }

  let(:agent) do
    user = create(:agent, roles: [Role.find_by(name: 'Agent'), role_group_d])
    user.user_groups.create! group: group_a, access: :full
    user.user_groups.create! group: group_c, access: :full
    user
  end

  let(:other_agent) { create(:agent) }
  let(:customer)    { create(:customer) }

  let(:form_id) { 12_345 }

  let(:base_params) do
    {
      name:     'draft name',
      group_id: group_a.id,
      form_id:  form_id,
      content:  { attrs: true }
    }
  end

  let(:path)                   { '/api/v1/tickets/shared_drafts' }
  let(:path_draft_a)           { "#{path}/#{draft_a.id}" }
  let(:path_draft_b)           { "#{path}/#{draft_b.id}" }
  let(:path_draft_d)           { "#{path}/#{draft_d.id}" }
  let(:path_draft_nonexistant) { "#{path}/asd" }

  describe 'request handling' do
    describe '#index' do
      it 'returns drafts that user has access to' do
        draft_a && draft_b && draft_d

        get path, as: :json

        expect(json_response).to include('shared_draft_ids' => [draft_a.id, draft_d.id])
      end

      it 'returns empty array when no drafts available' do
        get path, as: :json

        expect(json_response).to include('shared_draft_ids' => [])
      end

      it 'raises error when user has no permissions', authenticated_as: :customer do
        get path, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe '#show' do
      it 'returns draft' do
        get path_draft_a, as: :json

        expect(json_response).to include('shared_draft_id' => draft_a.id)
      end

      it 'returns 404 when draft does not exist' do
        get path_draft_nonexistant, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 when user has no permissions to drafts', authenticated_as: :other_agent do
        get path_draft_b, as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 404 when user has no permissions to this draft' do
        get path_draft_b, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns error when user has no permissions', authenticated_as: :customer do
        get path_draft_b, as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'grants access via role groups' do
        get path_draft_d, as: :json

        expect(json_response).to include('shared_draft_id' => draft_d.id)
      end
    end

    describe '#create' do
      it 'creates draft' do
        post path, params: base_params, as: :json

        expect(Ticket::SharedDraftStart).to be_exist json_response['shared_draft_id']
      end

      it 'creates draft with attachment' do
        create(:store, :image, o_id: form_id)

        post path, params: base_params, as: :json

        new_draft = Ticket::SharedDraftStart.find json_response['shared_draft_id']

        expect(new_draft.attachments).to be_one
      end

      it 'verifies user has access to given group' do
        post path, params: base_params.merge(group_id: group_b.id), as: :json

        expect(json_response).to include 'error_human' => %r{does not have access}
      end

      it 'grants access via role groups' do
        post path, params: base_params.merge(group_id: group_d.id), as: :json

        expect(Ticket::SharedDraftStart).to be_exist json_response['shared_draft_id']
      end

      it 'raises error when user has no create permission on any group', authenticated_as: :other_agent do
        post path, params: base_params, as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'raises error when user has no permissions', authenticated_as: :customer do
        post path, params: base_params, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe '#update' do
      it 'updates draft' do
        patch path_draft_a, params: base_params, as: :json

        expect(draft_a.reload).to have_attributes(content: { attrs: true })
      end

      it 'updates draft with attachment' do
        create(:store, :image, o_id: form_id)

        expect { patch path_draft_a, params: base_params, as: :json }
          .to change { draft_a.attachments.count }
          .by(1)
      end

      it 'updates draft to have no attachments' do
        create(:store, :image, o_id: draft_a.id, object: draft_a.class.name)

        expect { patch path_draft_a, params: base_params, as: :json }
          .to change { draft_a.attachments.count }
          .by(-1)
      end

      it 'returns 404 when draft does not exist' do
        patch path_draft_nonexistant, params: base_params, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'changes draft group' do
        agent.user_groups.create! group: group_b, access: :full

        patch path_draft_b, params: base_params.merge(group_id: group_b.id), as: :json

        expect(draft_b.reload.group).to eq group_b
      end

      it 'returns updated draft ID' do
        patch path_draft_a, params: base_params, as: :json

        expect(json_response).to include 'shared_draft_id' => draft_a.id
      end

      it 'verifies user has access to given groups' do
        patch path_draft_a, params: base_params.merge(group_id: group_b.id), as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'grants access via role groups' do
        patch path_draft_d, params: base_params.merge(group_id: group_d.id), as: :json

        expect(json_response).to include 'shared_draft_id' => draft_d.id
      end

      it 'returns error when user has no permissions', authenticated_as: :customer do
        patch path_draft_a, params: base_params, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe '#destroy' do
      it 'destroys draft' do
        delete path_draft_a, as: :json

        expect(Ticket::SharedDraftStart).not_to be_exist draft_a.id
      end

      it 'grants access via role groups' do
        delete path_draft_d, as: :json

        expect(Ticket::SharedDraftStart).not_to be_exist draft_d.id
      end

      it 'returns 404 when draft does not exist' do
        delete path_draft_nonexistant, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 when user has no permissions to this draft' do
        delete path_draft_b, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns error when user has no permissions', authenticated_as: :customer do
        delete path_draft_b, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe '#import_attachments' do
      let(:import_path_a) { "#{path_draft_a}/import_attachments" }
      let(:import_path_d) { "#{path_draft_d}/import_attachments" }
      let(:import_params) do
        {
          form_id: form_id
        }
      end

      it 'imports attachments from draft to given form ID' do
        create(:store, :image, o_id: draft_a.id, object: draft_a.class.name)

        expect { post import_path_a, params: import_params, as: :json }
          .to change { Store.list(object: 'UploadCache', o_id: form_id).count }
          .by(1)
      end

      it 'grants access via role groups' do
        create(:store, :image, o_id: draft_d.id, object: draft_d.class.name)

        expect { post import_path_d, params: import_params, as: :json }
          .to change { Store.list(object: 'UploadCache', o_id: form_id).count }
          .by(1)
      end

      it 'returns success if draft has no attachments' do
        post import_path_a, params: import_params, as: :json

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'clean up' do
    it 'removes draft when creating a ticket' do
      post_new_ticket group_a.id, draft_a.id

      expect(Ticket::SharedDraftStart).not_to be_exist(draft_a.id)
    end

    it 'grants access via role groups' do
      post_new_ticket group_d.id, draft_d.id

      expect(Ticket::SharedDraftStart).not_to be_exist(draft_d.id)
    end

    it 'not removes draft when fails creating a ticket' do
      post_new_ticket group_a.id, draft_a.id, valid: false

      expect(Ticket::SharedDraftStart).to be_exist(draft_a.id)
    end

    it 'raises error if draft is not applicable in this context' do
      post_new_ticket group_b.id, draft_a.id

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'keeps draft if not applicable in this context' do
      post_new_ticket group_b.id, draft_a.id

      expect(Ticket::SharedDraftStart).to be_exist(draft_a.id)
    end

    it 'raises error if group does not support drafts' do
      post_new_ticket group_c.id, draft_c.id

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'succeeds when draft does not exist' do
      post_new_ticket group_a.id, 1_234

      expect(response).to have_http_status(:created)
    end

    def post_new_ticket(group_id, shared_draft_id, valid: true)
      params = {
        title:           'a new ticket #1',
        group_id:        group_id,
        customer_id:     create(:customer).id,
        shared_draft_id: shared_draft_id,
        article:         {
          content_type: 'text/plain',
          body:         valid ? 'some body' : nil,
          sender:       'Customer',
          type:         'note',
        },
      }

      post '/api/v1/tickets', params: params, as: :json
    end
  end
end
