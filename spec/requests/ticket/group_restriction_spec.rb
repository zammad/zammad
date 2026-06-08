# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket REST API - Group Restriction', :aggregate_failures, type: :request do
  let(:group_1)  { create(:group, name: 'Sales') }
  let(:group_2)  { create(:group, name: 'Support') }
  let(:customer) { create(:customer) }
  let(:ticket)   { create(:ticket, title: 'Test Ticket', group: group_1, customer:) }

  describe 'PUT /api/v1/tickets/:id - group_id restriction for ticket.customer' do
    it 'ignores group_id change attempt by customer with ticket.customer permission' do
      authenticated_as(customer)
      put "/api/v1/tickets/#{ticket.id}", params: { group_id: group_2.id }, as: :json

      expect(response).to have_http_status(:ok)
      expect(ticket.reload.group_id).to eq(group_1.id)
    end

    it 'ignores both title update and group_id change, only applies title' do
      authenticated_as(customer)
      put "/api/v1/tickets/#{ticket.id}",
          params: { title: 'New Title', group_id: group_2.id },
          as:     :json

      expect(response).to have_http_status(:ok)
      ticket.reload
      expect(ticket.title).to eq('New Title')
      expect(ticket.group_id).to eq(group_1.id)
    end
  end

  describe 'PUT /api/v1/tickets/:id - group_id permission for ticket.agent' do
    let(:agent) { create(:agent, groups: [group_1, group_2]) }

    it 'allows agent to change group_id' do
      authenticated_as(agent)
      put "/api/v1/tickets/#{ticket.id}", params: { group_id: group_2.id }, as: :json

      expect(response).to have_http_status(:ok)
      expect(ticket.reload.group_id).to eq(group_2.id)
    end
  end
end
