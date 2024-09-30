# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Checklist', authenticated_as: :agent, current_user_id: 1, type: :request do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group], group_names_access_map: { group.name => %w[read change] }) }
  let(:ticket) { create(:ticket, group: group) }

  describe '#show' do
    let(:checklist) { create(:checklist, ticket: ticket) }

    before do
      checklist
    end

    context 'when user is not authorized' do
      let(:agent) { create(:agent) }

      it 'returns forbidden status' do
        get "/api/v1/tickets/#{ticket.id}/checklist", as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is authorized' do
      it 'returns ok status' do
        get "/api/v1/tickets/#{ticket.id}/checklist"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe '#create', current_user_id: 1 do
    context 'when user is not authorized' do
      let(:agent) { create(:agent, groups: [group], group_names_access_map: { group.name => 'read' }) }

      it 'returns forbidden status' do
        post "/api/v1/tickets/#{ticket.id}/checklist"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is authorized' do
      it 'returns ok status' do
        post "/api/v1/tickets/#{ticket.id}/checklist"
        expect(response).to have_http_status(:ok)
      end

      context 'when ticket already has a checklist' do
        before do
          create(:checklist, ticket:)
        end

        it 'returns unprocessable entity', aggregate_failures: true do
          post "/api/v1/tickets/#{ticket.id}/checklist", as: :json
          expect(response).to have_http_status(:unprocessable_entity)
        end
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
