# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket::Article API > Time Accounting', :aggregate_failures, type: :request do
  let(:ticket) { create(:ticket) }
  let(:agent)  { create(:agent, groups: Group.all) }

  describe 'GET /api/v1/ticket_articles' do
    let(:article)        { create(:ticket_article, ticket: ticket) }
    let(:accounted_time) { create(:ticket_time_accounting, ticket: ticket, ticket_article: article, time_unit: 42) }

    before do
      article && accounted_time

      authenticated_as(agent)
      get "/api/v1/ticket_articles/#{article.id}?expand=true"
    end

    context 'when no time was accounted' do
      let(:accounted_time) { nil }

      it 'returns nil' do
        expect(response).to have_http_status(:ok)
        expect(json_response['time_unit']).to be_nil
      end
    end

    context 'when time was accounted' do
      it 'returns the accounted time' do
        expect(response).to have_http_status(:ok)
        expect(json_response['time_unit']).to eq(accounted_time.time_unit.to_s)
      end
    end
  end

  describe 'PUT /api/v1/tickets/:id' do
    let(:params) do
      {
        article: article
      }
    end

    let(:article) do
      {
        body:                   'Some example body.',
        time_unit:              time_unit,
        accounted_time_type_id: accounted_time_type_id
      }
    end

    let(:time_unit)                { 42 }
    let(:accounted_time_type_id)   { nil }
    let(:time_accounting_enabled)  { true }

    before do
      Setting.set('time_accounting', time_accounting_enabled)

      ticket

      authenticated_as(agent)
      put "/api/v1/tickets/#{ticket.id}", params: params, as: :json
    end

    context 'when time accounting disabled' do
      let(:time_accounting_enabled) { false }

      it 'does not create ticket article' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'without accounted time type' do
      it 'created accounted time entry for article' do
        expect(response).to have_http_status(:ok)
        expect(Ticket::TimeAccounting.last.time_unit).to eq(42)
      end
    end

    context 'with accounted time type' do
      let(:accounted_time_type)    { create(:ticket_time_accounting_type) }
      let(:accounted_time_type_id) { accounted_time_type.id }

      it 'created accounted time entry for article' do
        expect(response).to have_http_status(:ok)
        expect(Ticket::TimeAccounting.last.time_unit).to eq(42)
        expect(Ticket::TimeAccounting.last.type.id).to eq(accounted_time_type_id)
      end

      context 'with type name' do
        let(:article) do
          {
            body:                'Some example body.',
            time_unit:           time_unit,
            accounted_time_type: accounted_time_type.name
          }
        end

        it 'created accounted time entry for article' do
          expect(response).to have_http_status(:ok)
          expect(Ticket::TimeAccounting.last.time_unit).to eq(42)
          expect(Ticket::TimeAccounting.last.type.id).to eq(accounted_time_type_id)
        end
      end
    end
  end
end
