# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mention', aggregate_failures: true, authenticated_as: :user, type: :request do
  let(:ticket)       { create(:ticket) }
  let(:other_ticket) { create(:ticket) }
  let(:user)         { create(:agent_and_customer, groups: [ticket.group]) }
  let(:other_user)   { create(:agent_and_customer, groups: [ticket.group]) }
  let(:mention)      { create(:mention, mentionable: ticket, user: user) }

  describe 'GET /api/v1/mentions' do
    before { mention }

    context 'when user has agent access to mentionable' do
      it 'returns mentions' do
        get '/api/v1/mentions', params: { mentionable_type: 'Ticket', mentionable_id: ticket.id }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response['mentions'].count).to eq(1)
      end

      it 'returns mentions for another user who has access', authenticated_as: :other_user do
        get '/api/v1/mentions', params: { mentionable_type: 'Ticket', mentionable_id: ticket.id }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response['mentions'].count).to eq(1)
      end

      it 'returns empty list for object without mentions' do
        user.user_groups.create! group: other_ticket.group, access: 'read'

        get '/api/v1/mentions', params: { mentionable_type: 'Ticket', mentionable_id: other_ticket.id }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response['mentions']).to be_blank
      end

      context 'when requesting full response' do
        it 'returns related assets' do
          get '/api/v1/mentions?full=1', params: { mentionable_type: 'Ticket', mentionable_id: ticket.id }, as: :json
          expect(json_response['assets']).to include_assets_of mention, user, ticket
        end

        it 'returns mentions IDs' do
          get '/api/v1/mentions?full=1', params: { mentionable_type: 'Ticket', mentionable_id: ticket.id }, as: :json
          expect(json_response['record_ids']).to match_array mention.id
        end
      end
    end

    context 'when user has no access to mentionable' do
      it 'returns authorization error' do
        get '/api/v1/mentions', params: { mentionable_type: 'Ticket', mentionable_id: other_ticket.id }, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when invalid mentionable is given' do
      it 'fails if non-existant ticket given' do
        get '/api/v1/mentions', params: { mentionable_type: 'Ticket', mentionable_id: 0 }, as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'fails if non-ticket given' do
        get '/api/v1/mentions', params: { mentionable_type: 'NonTicket', mentionable_id: ticket.id }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq("The parameter 'mentionable_type' is invalid.")
      end
    end
  end

  describe 'POST /api/v1/mentions' do
    let(:params) do
      {
        mentionable_type: 'Ticket',
        mentionable_id:   other_ticket.id
      }
    end

    context 'when user has agent access' do
      before do
        user.group_names_access_map = {
          other_ticket.group.name => 'read',
        }
      end

      it 'subscribes to a given ticket' do
        expect { post '/api/v1/mentions', params: params, as: :json }
          .to change { other_ticket.mentions.reload.count }.to(1)

        expect(response).to have_http_status(:created)
      end

      it 'silently handles subscribing to item already subscribed to' do
        create(:mention, mentionable: other_ticket, user: user)

        expect { post '/api/v1/mentions', params: params, as: :json }
          .not_to change { other_ticket.mentions.reload.count }

        expect(response).to have_http_status(:created)
      end
    end

    context 'when user has no access' do
      it 'fails' do
        post '/api/v1/mentions', params: params, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/mentions/:id' do
    before { mention }

    context 'when user has agent access' do
      it 'deletes mention' do
        expect { delete "/api/v1/mentions/#{mention.id}", as: :json }
          .to change { ticket.mentions.reload.count }.by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'fails to delete mention that is no longer present' do
        mention.destroy!

        delete "/api/v1/mentions/#{mention.id}", as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'does not allow to delete mention of another user' do
        create(:mention, mentionable: ticket, user: other_user)

        other_mention = Mention.last

        delete "/api/v1/mentions/#{other_mention.id}", as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user has no access' do
      before do
        user.user_groups.first.destroy!
      end

      it 'fails deleting non existant mention' do
        delete '/api/v1/mentions/0', as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'allows to delete mention on object user no longer has access to' do
        expect { delete "/api/v1/mentions/#{mention.id}", as: :json }
          .to change { ticket.mentions.reload.count }.to(0)

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
