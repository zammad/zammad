# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket::TimeAccounting API', :aggregate_failures, type: :request do
  let(:ticket) { create(:ticket) }
  let(:user)   { create(:agent, groups: Group.all) }

  describe 'GET /api/v1/tickets/:ticket_id/time_accountings' do
    let(:time_accounting_list) { create_list(:ticket_time_accounting, 3, ticket: ticket, time_unit: 10) }

    before do
      time_accounting_list

      authenticated_as(user)
      get "/api/v1/tickets/#{ticket.id}/time_accountings"
    end

    it 'returns the accounted time entry' do
      expect(response).to have_http_status(:ok)
      expect(json_response.pluck('id')).to eq(time_accounting_list.pluck(:id))
    end
  end

  describe 'GET /api/v1/tickets/:ticket_id/time_accountings/:id' do
    let(:time_accounting) { create(:ticket_time_accounting, ticket: ticket, time_unit: 22) }

    before do
      time_accounting

      authenticated_as(user)
      get "/api/v1/tickets/#{ticket.id}/time_accountings/#{time_accounting.id}"
    end

    it 'returns the accounted time entry' do
      expect(response).to have_http_status(:ok)
      expect(json_response['time_unit']).to eq('22.0')
    end
  end

  describe 'POST /api/v1/tickets/:ticket_id/time_accountings' do
    let(:article)                  { create(:ticket_article, ticket: ticket) }
    let(:params)                   { { time_unit: 11, ticket_articke_id: article.id } }
    let(:time_accounting_enabled)  { true }

    before do
      Setting.set('time_accounting', time_accounting_enabled)

      article

      authenticated_as(user)
      post "/api/v1/tickets/#{ticket.id}/time_accountings", params: params, as: :json
    end

    context 'with article' do
      it 'returns the created accounted time entry' do
        expect(response).to have_http_status(:created)
        expect(json_response['time_unit']).to eq('11.0')
      end
    end

    context 'without article' do
      let(:params) { { time_unit: 11 } }

      it 'returns the created accounted time entry' do
        expect(response).to have_http_status(:created)
        expect(json_response['time_unit']).to eq('11.0')
      end
    end

    context 'when time accounting disabled' do
      let(:time_accounting_enabled) { false }

      it 'does not create ticket article' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PUT /api/v1/tickets/:ticket_id/time_accountings/:id' do
    let(:time_accounting) { create(:ticket_time_accounting, ticket: ticket, time_unit: 22) }
    let(:params)          { { time_unit: 15 } }

    before do
      time_accounting

      authenticated_as(user)
      put "/api/v1/tickets/#{ticket.id}/time_accountings/#{time_accounting.id}", params: params, as: :json
    end

    context 'without admin permission' do

      it 'forbidden to update' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with admin permission' do
      let(:user) { create(:admin, groups: Group.all) }

      it 'returns the updated accounted time entry' do
        expect(response).to have_http_status(:ok)
        expect(json_response['time_unit']).to eq('15.0')
      end
    end
  end

  describe 'DELETE /api/v1/tickets/:ticket_id/time_accountings/:id' do
    let(:time_accounting) { create(:ticket_time_accounting, ticket: ticket, time_unit: 22) }

    before do
      time_accounting

      authenticated_as(user)
      delete "/api/v1/tickets/#{ticket.id}/time_accountings/#{time_accounting.id}"
    end

    context 'without admin permission' do

      it 'forbidden to update' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with admin permission' do
      let(:user) { create(:admin, groups: Group.all) }

      it 'returns the updated accounted time entry' do
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
