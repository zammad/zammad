# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Time Accounting API endpoints', type: :request do
  let(:admin)    { create(:admin) }
  let(:agent)    { create(:agent) }
  let(:customer) { create(:customer) }
  let(:year)     { Time.current.year }
  let(:month)    { Time.current.month }

  describe '/api/v1/time_accounting/log/by_activity' do
    context 'when requesting a JSON response' do
      it 'responds with an JSON' do
        ticket = create(:ticket, customer: admin)
        create(:ticket_time_accounting, ticket: ticket, created_by_id: admin.id)
        create(:ticket_time_accounting, ticket: ticket, created_by_id: agent.id)

        authenticated_as(admin)
        get "/api/v1/time_accounting/log/by_activity/#{year}/#{month}", as: :json

        expect(json_response.first).to include('agent' => admin.fullname)
        expect(json_response.first).to include('customer' => admin.fullname)

        expect(json_response.second).to include('agent' => agent.fullname)
        expect(json_response.second).to include('customer' => admin.fullname)
      end
    end

    context 'when requesting a log report download' do
      it 'responds with an Excel spreadsheet' do
        create(:group)
        ticket  = create(:ticket, state: Ticket::State.lookup(name: 'open'), customer: customer)
        article = create(:ticket_article, ticket: ticket, type: Ticket::Article::Type.lookup(name: 'note'))

        create(:ticket_time_accounting, ticket_id: ticket.id, ticket_article_id: article.id)

        authenticated_as(admin)
        get "/api/v1/time_accounting/log/by_activity/#{year}/#{month}?download=true", params: {}

        expect(response).to have_http_status(:ok)
        expect(response['Content-Disposition']).to be_truthy
        expect(response['Content-Disposition']).to eq("attachment; filename=\"by_activity-#{year}-#{month}.xls\"; filename*=UTF-8''by_activity-#{year}-#{month}.xls")
        expect(response['Content-Type']).to eq('application/vnd.ms-excel')
      end
    end
  end

  describe '/api/v1/time_accounting/log/by_ticket' do
    context 'when requesting a JSON response' do
      # see https://github.com/zammad/zammad/pull/2243
      context 'and logs exist for work performed by an agent who is also the customer of the ticket (#2243)' do
        let(:ticket) { create(:ticket, customer: admin) }
        let!(:time_log) { create(:ticket_time_accounting, ticket: ticket, created_by_id: admin.id) }

        it 'responds with a non-nil value for each :agent key' do
          authenticated_as(admin)
          get "/api/v1/time_accounting/log/by_ticket/#{year}/#{month}", as: :json

          expect(json_response.first).not_to include('agent' => nil)
        end
      end
    end

    context 'when requesting a log report download' do
      it 'responds with an Excel spreadsheet' do
        create(:group)
        ticket  = create(:ticket, state: Ticket::State.lookup(name: 'open'), customer: customer)
        article = create(:ticket_article, ticket: ticket, type: Ticket::Article::Type.lookup(name: 'note'))

        create(:ticket_time_accounting, ticket_id: ticket.id, ticket_article_id: article.id)

        authenticated_as(admin)
        get "/api/v1/time_accounting/log/by_ticket/#{year}/#{month}?download=true", params: {}

        expect(response).to have_http_status(:ok)
        expect(response['Content-Disposition']).to be_truthy
        expect(response['Content-Disposition']).to eq("attachment; filename=\"by_ticket-#{year}-#{month}.xls\"; filename*=UTF-8''by_ticket-#{year}-#{month}.xls")
        expect(response['Content-Type']).to eq('application/vnd.ms-excel')
      end
    end

    # Regression test for issue #2398 - Missing custom object in database causes error on export in time_accounting
    # This test is identical to the above one, except with the added step of a pending migration in the beginning
    context 'with pending attribute migrations, requesting a log report download' do
      it 'responds with an Excel spreadsheet' do
        ObjectManager::Attribute.add attributes_for :object_manager_attribute_select

        create(:group)
        ticket  = create(:ticket, state: Ticket::State.lookup(name: 'open'), customer: customer)
        article = create(:ticket_article, ticket: ticket, type: Ticket::Article::Type.lookup(name: 'note'))

        create(:ticket_time_accounting, ticket_id: ticket.id, ticket_article_id: article.id)

        authenticated_as(admin)
        get "/api/v1/time_accounting/log/by_ticket/#{year}/#{month}?download=true", params: {}

        expect(response).to have_http_status(:ok)
        expect(response['Content-Disposition']).to be_truthy
        expect(response['Content-Disposition']).to eq("attachment; filename=\"by_ticket-#{year}-#{month}.xls\"; filename*=UTF-8''by_ticket-#{year}-#{month}.xls")
        expect(response['Content-Type']).to eq('application/vnd.ms-excel')
      end
    end

  end

  describe 'Assign user to multiple organizations #1573' do
    let(:organization1) { create(:organization) }
    let(:organization2) { create(:organization) }
    let(:customer)      { create(:customer, organization: organization1, organizations: [organization2]) }
    let(:ticket1) do
      ticket  = create(:ticket, state: Ticket::State.lookup(name: 'open'), customer: customer, organization: organization1)
      article = create(:ticket_article, ticket: ticket, type: Ticket::Article::Type.lookup(name: 'note'))
      create(:ticket_time_accounting, ticket_id: ticket.id, ticket_article_id: article.id)
    end
    let(:ticket2) do
      ticket  = create(:ticket, state: Ticket::State.lookup(name: 'open'), customer: customer, organization: organization2)
      article = create(:ticket_article, ticket: ticket, type: Ticket::Article::Type.lookup(name: 'note'))
      create(:ticket_time_accounting, ticket_id: ticket.id, ticket_article_id: article.id)
    end

    before do
      ticket1 && ticket2
    end

    it 'does return results group by organization and customer so multi organization support is given' do
      authenticated_as(admin)
      get "/api/v1/time_accounting/log/by_customer/#{year}/#{month}", as: :json
      expect(json_response.count).to eq(2)
      expect(json_response[0]['organization']['id']).to eq(organization1.id)
      expect(json_response[0]['time_unit']).to eq(ticket1.time_unit.to_s)
      expect(json_response[1]['organization']['id']).to eq(organization2.id)
      expect(json_response[1]['time_unit']).to eq(ticket2.time_unit.to_s)
    end
  end
end
