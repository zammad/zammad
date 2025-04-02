# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Selector', authenticated_as: :admin, type: :request do
  let(:admin) { create(:admin) }

  describe 'Ticket' do
    let(:ticket_1)   { create(:ticket) }
    let(:ticket_2)   { create(:ticket) }
    let(:ticket_3)   { create(:ticket) }

    before do
      ticket_1 && ticket_2 && ticket_3
    end

    it 'does find tickets by title', :aggregate_failures do
      condition = {
        operator:   'OR',
        conditions: [
          {
            name:     'ticket.title',
            operator: 'contains',
            value:    ticket_1.title,
          },
          {
            name:     'ticket.title',
            operator: 'contains',
            value:    ticket_2.title,
          },
          {
            name:     'ticket.title',
            operator: 'contains',
            value:    ticket_3.title,
          },
        ]
      }

      params = {
        condition: condition
      }
      post '/api/v1/tickets/selector', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['object_ids'].count).to eq(3)
    end
  end

  describe 'User' do
    let(:user_1)   { create(:user, firstname: 'User-1') }
    let(:user_2)   { create(:user, firstname: 'User-2') }
    let(:user_3)   { create(:user, firstname: 'User-3') }

    before do
      user_1 && user_2 && user_3
    end

    it 'does find users by firstname', :aggregate_failures do
      condition = {
        operator:   'OR',
        conditions: [
          {
            name:     'user.firstname',
            operator: 'contains',
            value:    user_1.firstname,
          },
          {
            name:     'user.firstname',
            operator: 'contains',
            value:    user_2.firstname,
          },
          {
            name:     'user.firstname',
            operator: 'contains',
            value:    user_3.firstname,
          },
        ]
      }

      params = {
        condition: condition
      }
      post '/api/v1/users/selector', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['object_ids'].count).to eq(3)
    end
  end

  describe 'Organization' do
    let(:organization_1)   { create(:organization, name: 'Org-1') }
    let(:organization_2)   { create(:organization, name: 'Org-2') }
    let(:organization_3)   { create(:organization, name: 'Org-3') }

    before do
      organization_1 && organization_2 && organization_3
    end

    it 'does find organizations by name', :aggregate_failures do
      condition = {
        operator:   'OR',
        conditions: [
          {
            name:     'organization.name',
            operator: 'contains',
            value:    organization_1.name,
          },
          {
            name:     'organization.name',
            operator: 'contains',
            value:    organization_2.name,
          },
          {
            name:     'organization.name',
            operator: 'contains',
            value:    organization_3.name,
          },
        ]
      }

      params = {
        condition: condition
      }
      post '/api/v1/organizations/selector', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['object_ids'].count).to eq(3)
    end
  end

  describe 'handling wrong parameters', aggregate_failures: true do
    it 'returns error for non existant type' do
      post '/api/v1/blablabla/selector', params: nil, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error_human']).to eq('Given object does not support selector')
    end

    it 'returns error for object that does not support selectors' do
      post '/api/v1/groups/selector', params: nil, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error_human']).to eq('Given object does not support selector')
    end
  end
end
