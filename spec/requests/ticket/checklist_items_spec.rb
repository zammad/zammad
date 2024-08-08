# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Checklist Items', authenticated_as: :agent, type: :request do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group], group_names_access_map: { group.name => %w[read change] }) }
  let(:ticket) { create(:ticket, group: group) }

  describe '#create' do
    let(:checklist) { create(:checklist, ticket: ticket) }

    let(:checklist_item_params) do
      {
        text: 'foobar',
      }
    end

    before do
      checklist
      post "/api/v1/tickets/#{ticket.id}/checklist/items", params: checklist_item_params
    end

    context 'when user is not authorized' do
      let(:agent) { create(:agent, groups: [group], group_names_access_map: { group.name => 'read' }) }

      it 'returns forbidden status' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is authorized' do
      it 'returns ok status' do
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe '#update' do
    let(:checklist) { create(:checklist, ticket: ticket) }

    let(:checklist_item_params) do
      {
        checked: true,
      }
    end

    before do
      put "/api/v1/tickets/#{ticket.id}/checklist/items/#{checklist.items.last.id}", params: checklist_item_params
    end

    context 'when user is not authorized' do
      let(:agent) { create(:agent, groups: [group], group_names_access_map: { group.name => 'read' }) }

      it 'returns forbidden status' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is authorized' do
      it 'returns ok status' do
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe '#destroy' do
    let(:checklist) { create(:checklist, ticket: ticket) }

    before do
      delete "/api/v1/tickets/#{ticket.id}/checklist/items/#{checklist.items.last.id}"
    end

    context 'when user is not authorized' do
      let(:agent) { create(:agent, groups: [group], group_names_access_map: { group.name => 'read' }) }

      it 'returns forbidden status' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is authorized' do
      it 'returns ok status' do
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
