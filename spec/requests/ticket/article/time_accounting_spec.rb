# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket::Article API > Time Accounting', :aggregate_failures, type: :request do
  describe 'GET /api/v1/ticket_articles' do
    let(:agent)          { create(:agent, groups: Group.all) }
    let(:ticket)         { create(:ticket) }
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
end
