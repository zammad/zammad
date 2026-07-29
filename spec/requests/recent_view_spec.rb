# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'RecentView', type: :request do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, group:) }

  describe 'POST /api/v1/recent_view', authenticated_as: :agent do
    it 'logs a viewed object the user can access', :aggregate_failures do
      expect { post '/api/v1/recent_view', params: { object: 'Ticket', o_id: ticket.id }, as: :json }
        .to change { RecentView.exists?(recent_view_object_id: ObjectLookup.by_name('Ticket'), o_id: ticket.id, created_by_id: agent.id) }
        .to(true)

      expect(response).to have_http_status(:ok)
    end

    it 'does not log a record the user cannot access', :aggregate_failures do
      inaccessible_ticket = create(:ticket, group: create(:group))

      expect { post '/api/v1/recent_view', params: { object: 'Ticket', o_id: inaccessible_ticket.id }, as: :json }
        .not_to change(RecentView, :count)

      expect(response).to have_http_status(:ok)
    end

    it 'does not log a non-existent record', :aggregate_failures do
      expect { post '/api/v1/recent_view', params: { object: 'Ticket', o_id: 99_999_999 }, as: :json }
        .not_to change(RecentView, :count)

      expect(response).to have_http_status(:ok)
    end

    it 'does not log for a non-ObjectLookup class', :aggregate_failures do
      expect { post '/api/v1/recent_view', params: { object: 'BackgroundServices', o_id: 1 }, as: :json }
        .not_to change(RecentView, :count)

      expect(response).to have_http_status(:ok)
    end

    it 'does not log for a non-existent class', :aggregate_failures do
      expect { post '/api/v1/recent_view', params: { object: 'NonExistentClass', o_id: 1 }, as: :json }
        .not_to change(RecentView, :count)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /api/v1/recent_view' do
    let(:organization) { create(:organization) }
    let(:customer)     { create(:customer, organization:) }
    let(:colleague)    { create(:customer, organization:) }

    context 'when a customer viewed a colleague of the same organization', authenticated_as: :customer do
      it 'lists the object it logged', :aggregate_failures do
        post '/api/v1/recent_view', params: { object: 'User', o_id: colleague.id }, as: :json
        expect(response).to have_http_status(:ok)

        get '/api/v1/recent_view?full=true', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response['record_ids'].count).to eq(1)
        expect(json_response['assets']['User']).to include(colleague.id.to_s)
      end
    end
  end
end
