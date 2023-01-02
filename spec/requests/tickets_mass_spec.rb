# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'TicketsMass', authenticated_as: :user, type: :request do
  let(:user)  { create(:agent, groups: [group_a, group_b]) }
  let(:owner) { create(:agent) }

  let(:group_a) { create(:group) }
  let(:group_b) { create(:group) }
  let(:group_c) { create(:group) }

  let(:ticket_a) { create(:ticket, group: group_a, owner: owner) }
  let(:ticket_b) { create(:ticket, group: group_b, owner: owner) }
  let(:ticket_c) { create(:ticket, group: group_c, owner: owner) }

  let(:core_workflow) do
    create(:core_workflow, :active_and_screen, :condition_group, :perform_action, group: group_b)
  end

  describe 'POST /tickets/mass_macro' do
    let(:macro_perform) do
      {
        'ticket.priority_id': { pre_condition: 'specific', value: 3.to_s }
      }
    end
    let(:macro) { create(:macro, perform: macro_perform) }
    let(:macro_groups) { create(:macro, groups: [group_a], perform: macro_perform) }

    it 'applies macro' do
      post '/api/v1/tickets/mass_macro', params: { macro_id: macro.id, ticket_ids: [ticket_a.id] }

      expect(ticket_a.reload.priority_id).to eq 3
    end

    it 'does not apply changes if one of ticket updates fail' do
      core_workflow

      post '/api/v1/tickets/mass_macro', params: { macro_id: macro.id, ticket_ids: [ticket_a.id, ticket_b.id] }, as: :json

      expect(ticket_a.reload.articles).not_to eq 3
    end

    it 'returns error if macro not applicable to at least one ticket' do
      post '/api/v1/tickets/mass_macro', params: { macro_id: macro_groups.id, ticket_ids: [ticket_a.id, ticket_b.id] }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'checks if user has write access to tickets' do
      post '/api/v1/tickets/mass_macro', params: { macro_id: macro_groups.id, ticket_ids: [ticket_a.id, ticket_c.id] }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST /tickets/mass_update' do
    it 'applies changes' do
      post '/api/v1/tickets/mass_update', params: { attributes: { priority_id: 3 }, ticket_ids: [ticket_a.id] }

      expect(ticket_a.reload.priority_id).to eq 3
    end

    it 'does not apply changes' do
      post '/api/v1/tickets/mass_update', params: { attributes: { priority_id: 3 }, ticket_ids: [ticket_c.id] }

      expect(ticket_c.reload.priority_id).not_to eq 3
    end

    it 'adds note' do
      post '/api/v1/tickets/mass_update', params: { attributes: {}, article: { body: 'test mass update body' }, ticket_ids: [ticket_a.id] }

      expect(ticket_a.reload.articles.last).to have_attributes(body: 'test mass update body')
    end

    it 'does not apply changes if one of ticket updates fail' do
      core_workflow

      post '/api/v1/tickets/mass_update', params: { attributes: { priority_id: 3 }, ticket_ids: [ticket_a.id, ticket_b.id] }

      expect(ticket_a.reload.priority_id).not_to eq 3
    end

    it 'checks if user has write access to tickets' do
      post '/api/v1/tickets/mass_update', params: { attributes: { priority_id: 3 }, ticket_ids: [ticket_a.id, ticket_c.id] }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
