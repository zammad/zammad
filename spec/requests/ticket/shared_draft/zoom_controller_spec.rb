# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Shared Drafts Zoom API endpoints', authenticated_as: :agent, type: :request do

  let(:group)  { create(:group, shared_drafts: true) }
  let(:ticket) { create(:ticket, group: group) }

  let(:agent) do
    user = create(:agent)
    user.user_groups.create! group: ticket.group, access: :full
    user
  end

  let(:other_agent) { create(:agent) }

  let(:path)              { "/api/v1/tickets/#{ticket.id}/shared_draft" }
  let(:non_existant_path) { "/api/v1/tickets/a#{ticket.id}/shared_draft" }

  describe 'request handling' do
    describe '#show' do
      it 'returns draft' do
        draft = create(:ticket_shared_draft_zoom, ticket: ticket)

        get path, as: :json

        expect(json_response).to include('shared_draft_id' => draft.id)
      end

      it 'returns empty when draft does not exist' do
        get path, as: :json

        expect(json_response).to include('shared_draft_id' => nil)
      end

      it 'raises error when ticket does not exist' do
        get non_existant_path, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'raises error when user has no permissions', authenticated_as: :other_agent do
        get path, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe '#update' do
      let(:form_id) { 12_345 }
      let(:params) do
        {
          form_id:           form_id,
          ticket_attributes: { attrs: true }
        }
      end

      it 'creates draft if does not exist' do
        put path, params: params, as: :json

        shared_draft = ticket.reload_shared_draft

        expect(shared_draft).to have_attributes(ticket_attributes: { attrs: true })
      end

      it 'creates draft with attachment if does not exist' do
        create(:store, :image, o_id: form_id)

        put path, params: params, as: :json

        shared_draft = ticket.reload_shared_draft

        expect(shared_draft.attachments).to be_one
      end

      it 'updates draft' do
        shared_draft = create(:ticket_shared_draft_zoom, ticket: ticket)

        put path, params: params, as: :json

        expect(shared_draft.reload).to have_attributes(ticket_attributes: { attrs: true })
      end

      it 'updates draft with attachment' do
        shared_draft = create(:ticket_shared_draft_zoom, ticket: ticket)
        create(:store, :image, o_id: form_id)

        put path, params: params, as: :json

        expect(shared_draft.attachments).to be_one
      end

      it 'updates draft to have no attachments' do
        shared_draft = create(:ticket_shared_draft_zoom, ticket: ticket)
        create(:store, :image, o_id: shared_draft.id, object: shared_draft.class.name)
        create(:store, :image, o_id: form_id)

        put path, params: params, as: :json

        expect(shared_draft.attachments).to be_one
      end

      it 'raises error when user has no permissions', authenticated_as: :other_agent do
        put path, params: params, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'destroy' do
      it 'destroys draft' do
        draft = create(:ticket_shared_draft_zoom, ticket: ticket)

        delete path, as: :json

        expect(Ticket::SharedDraftZoom).not_to be_exists(draft.id)
      end

      it 'raises error if draft does not exist' do
        delete non_existant_path, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'raises error when user has no permissions', authenticated_as: :other_agent do
        delete path, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'import_attachments' do
      let(:import_path) { "#{path}/import_attachments" }
      let(:form_id)     { 456 }
      let(:params) do
        {
          form_id: form_id,
        }
      end

      it 'imports attachments from draft to given form ID' do
        draft = create(:ticket_shared_draft_zoom, ticket: ticket)
        create(:store, :image, o_id: draft.id, object: draft.class.name)

        expect { post import_path, params: params, as: :json }
          .to change { Store.list(object: 'UploadCache', o_id: form_id).count }
          .by(1)
      end

      it 'returns success if draft has no attachments' do
        create(:ticket_shared_draft_zoom, ticket: ticket)

        post import_path, params: params, as: :json

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'clean up' do
    let(:group) { create(:group, shared_drafts: true) }
    let(:draft_a) { create(:ticket_shared_draft_zoom, ticket: create(:ticket, group: group)) }
    let(:draft_b) { create(:ticket_shared_draft_zoom, ticket: create(:ticket, group: group)) }

    before do
      agent.user_groups.create! group: group, access: :full
    end

    it 'removes draft when updating a ticket' do
      put_ticket_update(draft_a.ticket.id, draft_a.id)

      expect(Ticket::SharedDraftZoom).not_to be_exist(draft_a.id)
    end

    it 'not removes draft when fails updating a ticket' do
      put_ticket_update(draft_a.ticket.id, draft_a.id, valid: false)

      expect(Ticket::SharedDraftZoom).to be_exist(draft_a.id)
    end

    it 'raises error if draft is not applicable in this context' do
      put_ticket_update(draft_a.ticket.id, draft_b.id)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'keeps draft if not applicable in this context' do
      put_ticket_update(draft_a.ticket.id, draft_b.id)

      expect(Ticket::SharedDraftZoom).to be_exist(draft_b.id)
    end

    it 'succeeds even if group is not eligible anymore' do
      group.update(shared_drafts: false)
      put_ticket_update(draft_a.ticket.id, 1234)

      expect(response).to have_http_status(:ok)
    end

    it 'removes given draft even if group is not eligible anymore' do
      group.update(shared_drafts: false)
      put_ticket_update(draft_a.ticket.id, draft_a.id)

      expect(Ticket::SharedDraftZoom).not_to be_exist(draft_a.id)
    end

    it 'succeeds when draft does not exist' do
      put_ticket_update(draft_a.ticket.id, 1234)

      expect(response).to have_http_status(:ok)
    end

    def put_ticket_update(ticket_id, shared_draft_id, valid: true)
      params = {
        article: {
          body:            valid ? 'some body' : nil,
          shared_draft_id: shared_draft_id
        }
      }

      put "/api/v1/tickets/#{ticket_id}", params: params, as: :json
    end
  end
end
