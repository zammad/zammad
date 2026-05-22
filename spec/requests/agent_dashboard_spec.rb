# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AgentDashboard', :aggregate_failures, type: :request do
  let!(:group)    { create(:group) }
  let!(:agent)    { create(:agent, groups: [group]) }
  let!(:customer) { create(:customer) }

  describe 'GET /api/v1/agent_dashboard/sla_at_risk' do
    let(:endpoint) { '/api/v1/agent_dashboard/sla_at_risk' }

    # Tickets' escalation_at is normally computed from SLA + state callbacks.
    # We bypass via update_columns so the test data is deterministic.
    let!(:ticket_breaching_soon) do
      t = create(:ticket, title: 'Soon', group: group, customer: customer,
                          state: Ticket::State.find_by(name: 'open'))
      t.update_columns(escalation_at: 30.minutes.from_now)
      t
    end
    let!(:ticket_breaching_later) do
      t = create(:ticket, title: 'Later', group: group, customer: customer,
                          state: Ticket::State.find_by(name: 'open'))
      t.update_columns(escalation_at: 2.hours.from_now)
      t
    end
    let!(:ticket_already_breached) do
      t = create(:ticket, title: 'Breached', group: group, customer: customer,
                          state: Ticket::State.find_by(name: 'open'))
      t.update_columns(escalation_at: 2.hours.ago)
      t
    end
    let!(:ticket_no_sla) do
      t = create(:ticket, title: 'NoSla', group: group, customer: customer,
                          state: Ticket::State.find_by(name: 'open'))
      t.update_columns(escalation_at: nil)
      t
    end
    let!(:ticket_closed) do
      t = create(:ticket, title: 'Closed', group: group, customer: customer,
                          state: Ticket::State.find_by(name: 'closed'))
      t.update_columns(escalation_at: 30.minutes.from_now)
      t
    end

    context 'as an agent' do
      before { authenticated_as(agent) }

      it 'returns tickets ordered by soonest escalation_at' do
        get endpoint, as: :json

        expect(response).to have_http_status(:ok)
        titles = json_response.map { |t| t['title'] }
        expect(titles).to start_with('Soon', 'Later')
      end

      it 'excludes tickets already past escalation_at' do
        get endpoint, as: :json
        ids = json_response.map { |t| t['id'] }
        expect(ids).not_to include(ticket_already_breached.id)
      end

      it 'excludes tickets without escalation_at' do
        get endpoint, as: :json
        ids = json_response.map { |t| t['id'] }
        expect(ids).not_to include(ticket_no_sla.id)
      end

      it 'excludes closed tickets' do
        get endpoint, as: :json
        ids = json_response.map { |t| t['id'] }
        expect(ids).not_to include(ticket_closed.id)
      end

      it 'respects within_hours param' do
        get endpoint, params: { within_hours: 1 }, as: :json
        titles = json_response.map { |t| t['title'] }
        expect(titles).to include('Soon')
        expect(titles).not_to include('Later')
      end
    end

    context 'as a customer' do
      before { authenticated_as(customer) }

      it 'is forbidden' do
        get endpoint, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'unauthenticated' do
      it 'is rejected' do
        get endpoint, as: :json
        expect(response.status).to be_in([401, 403])
      end
    end
  end

  describe 'GET /api/v1/agent_dashboard/workload' do
    let(:endpoint)      { '/api/v1/agent_dashboard/workload' }
    let!(:second_agent) { create(:agent, groups: [group]) }
    let!(:open_state)   { Ticket::State.find_by(name: 'open') }

    before do
      create_list(:ticket, 3, group: group, customer: customer, owner: agent,        state: open_state)
      create_list(:ticket, 1, group: group, customer: customer, owner: second_agent, state: open_state)
      authenticated_as(agent)
    end

    it 'returns each agent with their open ticket count' do
      get endpoint, as: :json
      expect(response).to have_http_status(:ok)
      row = json_response.find { |r| r['agent_id'] == agent.id }
      expect(row).to be_present
      expect(row['open_count']).to eq(3)
    end

    it 'orders by descending count' do
      get endpoint, as: :json
      first, second = json_response[0..1]
      expect(first['open_count']).to be >= second['open_count']
    end

    context 'as a customer' do
      it 'is forbidden' do
        authenticated_as(customer)
        get endpoint, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
