# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket::TimeAccounting API', :aggregate_failures, authenticated_as: :user, type: :request do
  let(:ticket) { create(:ticket) }
  let(:user)   { create(:agent, groups: [ticket.group]) }

  before do
    allow_any_instance_of(Controllers::TimeAccountingsControllerPolicy)
      .to receive(policy_action)
      .and_return(policy_response)
  end

  describe 'GET /api/v1/tickets/:ticket_id/time_accountings' do
    let(:time_accounting_list) { create_list(:ticket_time_accounting, 3, ticket: ticket, time_unit: 10) }
    let(:policy_action)        { :index? }

    before do
      time_accounting_list

      get "/api/v1/tickets/#{ticket.id}/time_accountings"
    end

    context 'with sufficient permissions' do
      let(:policy_response) { true }

      it 'returns the accounted time entry' do
        expect(response).to have_http_status(:ok)
        expect(json_response.pluck('id')).to eq(time_accounting_list.pluck(:id))
      end
    end

    context 'without sufficient permissions' do
      let(:policy_response) { false }

      it 'returns the updated accounted time entry' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /api/v1/tickets/:ticket_id/time_accountings/:id' do
    let(:time_accounting) { create(:ticket_time_accounting, ticket: ticket, time_unit: 22) }
    let(:policy_action)   { :show? }

    before do
      time_accounting

      get "/api/v1/tickets/#{ticket.id}/time_accountings/#{time_accounting.id}"
    end

    context 'with sufficient permissions' do
      let(:policy_response) { true }

      it 'returns the accounted time entry' do
        expect(response).to have_http_status(:ok)
        expect(json_response['time_unit']).to eq('22.0')
      end
    end

    context 'without sufficient permissions' do
      let(:policy_response) { false }

      it 'forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/tickets/:ticket_id/time_accountings' do
    let(:article)       { create(:ticket_article, ticket: ticket) }
    let(:params)        { { time_unit: 11, ticket_articke_id: article.id } }
    let(:policy_action) { :create? }

    before do
      article

      post "/api/v1/tickets/#{ticket.id}/time_accountings", params: params, as: :json
    end

    context 'with sufficient permissions' do
      let(:policy_response) { true }

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
    end

    context 'without sufficient permissions' do
      let(:policy_response) { false }

      it 'forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PUT /api/v1/tickets/:ticket_id/time_accountings/:id' do
    let(:time_accounting) { create(:ticket_time_accounting, ticket: ticket, time_unit: 22) }
    let(:params)          { { time_unit: 15 } }
    let(:policy_action)   { :method_missing } # workaround for default_permit!

    before do
      put "/api/v1/tickets/#{ticket.id}/time_accountings/#{time_accounting.id}", params: params, as: :json
    end

    context 'with sufficient permissions' do
      let(:policy_response) { true }

      it 'returns the updated accounted time entry' do

        expect(response).to have_http_status(:ok)
        expect(json_response['time_unit']).to eq('15.0')
      end
    end

    context 'without sufficient permissions' do
      let(:policy_response) { false }

      it 'forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/tickets/:ticket_id/time_accountings/:id' do
    let(:time_accounting) { create(:ticket_time_accounting, ticket: ticket, time_unit: 22) }
    let(:policy_action)   { :method_missing } # workaround for default_permit!

    before do
      delete "/api/v1/tickets/#{ticket.id}/time_accountings/#{time_accounting.id}"
    end

    context 'with sufficient permissions' do
      let(:policy_response) { true }

      it 'returns the updated accounted time entry' do
        expect(Ticket::TimeAccounting).not_to exist(time_accounting.id)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'without sufficient permissions' do
      let(:policy_response) { false }

      it 'forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
