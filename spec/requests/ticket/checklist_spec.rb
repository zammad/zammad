# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Checklist', authenticated_as: :agent, type: :request do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group], group_names_access_map: { group.name => %w[read change] }) }
  let(:ticket) { create(:ticket, group: group) }

  describe '#show' do
    let(:checklist) { create(:checklist, ticket: ticket) }

    before do
      checklist
      get "/api/v1/tickets/#{ticket.id}/checklist"
    end

    context 'when user is not authorized' do
      let(:agent) { create(:agent) }

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

  describe '#create' do
    before do
      post "/api/v1/tickets/#{ticket.id}/checklist"
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

    let(:checklist_params) do
      {
        name: 'foobar',
      }
    end

    before do
      checklist
      put "/api/v1/tickets/#{ticket.id}/checklist", params: checklist_params
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
      checklist
      delete "/api/v1/tickets/#{ticket.id}/checklist"
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
