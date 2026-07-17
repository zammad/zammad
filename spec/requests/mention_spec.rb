# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

        expect(response).to have_http_status(:unprocessable_content)
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

    context 'with participants feature (Agent-Add-Other via user_id)' do
      let(:customer) { create(:customer) }
      let(:agent_user) { create(:agent_and_customer, groups: [other_ticket.group]) }

      before do
        Setting.set('ticket_participants_enabled', true)
        agent_user.group_names_access_map = { other_ticket.group.name => 'full' }
      end

      after do
        Setting.set('ticket_participants_enabled', false)
      end

      it 'R1: agent with group-change adds customer → 201', authenticated_as: :agent_user do
        params_with_user = params.merge(user_id: customer.id)

        expect { post '/api/v1/mentions', params: params_with_user, as: :json }
          .to change { other_ticket.mentions.reload.count }.to(1)

        expect(response).to have_http_status(:created)
        expect(other_ticket.mentions.last.user_id).to eq(customer.id)
      end

      it 'R3: agent adds non-customer → 422', authenticated_as: :agent_user do
        non_customer = create(:agent, groups: [other_ticket.group])
        params_with_user = params.merge(user_id: non_customer.id)

        post '/api/v1/mentions', params: params_with_user, as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'R4: agent adds beyond cap 50 → 422', authenticated_as: :agent_user do
        # Create 50 existing customer participants
        50.times do
          c = create(:customer)
          create(:mention, mentionable: other_ticket, user: c)
        end

        new_customer = create(:customer)
        params_with_user = params.merge(user_id: new_customer.id)

        post '/api/v1/mentions', params: params_with_user, as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'R5-integration: agent with only group-read adds customer → 403', authenticated_as: :agent_user do
        agent_user.group_names_access_map = { other_ticket.group.name => 'read' }
        params_with_user = params.merge(user_id: customer.id)

        post '/api/v1/mentions', params: params_with_user, as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'Self-Subscribe ANCHOR: existing POST without user_id still works', authenticated_as: :agent_user do
        expect { post '/api/v1/mentions', params: params, as: :json }
          .to change { other_ticket.mentions.reload.count }.to(1)

        expect(response).to have_http_status(:created)
      end
    end
  end

  describe 'DELETE /api/v1/mentions/:id' do
    let(:agent_with_change) { create(:agent_and_customer, groups: [ticket.group]) }
    let(:agent_readonly)    { create(:agent_and_customer) }

    before do
      mention
      agent_with_change.group_names_access_map = { ticket.group.name => 'full' }
      agent_readonly.group_names_access_map    = { ticket.group.name => 'read' }
      Setting.set('ticket_participants_enabled', true)
    end

    after do
      Setting.set('ticket_participants_enabled', false)
    end

    context 'when user has agent access' do
      it 'deletes own mention' do
        expect { delete "/api/v1/mentions/#{mention.id}", as: :json }
          .to change { ticket.mentions.reload.count }.by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'fails to delete mention that is no longer present' do
        mention.destroy!

        delete "/api/v1/mentions/#{mention.id}", as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'RR1: agent with group-change removes other participant → 200', authenticated_as: :agent_with_change do
        other_participant = create(:customer)
        other_mention = create(:mention, mentionable: ticket, user: other_participant)

        expect { delete "/api/v1/mentions/#{other_mention.id}", as: :json }
          .to change { ticket.mentions.reload.count }.by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'RR3: agent with only group-read removes other → 403', authenticated_as: :agent_readonly do
        other_mention = create(:mention, mentionable: ticket, user: other_user)

        delete "/api/v1/mentions/#{other_mention.id}", as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user has no access' do
      let(:customer_user) { create(:customer) }

      before do
        user.user_groups.first.destroy!
      end

      it 'fails deleting non existant mention' do
        delete '/api/v1/mentions/0', as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'allows to delete own mention on object user no longer has group access to (self-removal still works)' do
        expect { delete "/api/v1/mentions/#{mention.id}", as: :json }
          .to change { ticket.mentions.reload.count }.to(0)

        expect(response).to have_http_status(:ok)
      end

      it 'RR2: customer removes other participant → 403' do
        customer_mention = create(:mention, mentionable: ticket, user: customer_user)

        expect { delete "/api/v1/mentions/#{customer_mention.id}", as: :json }
          .not_to change { ticket.mentions.reload.count }

        expect(response).to have_http_status(:forbidden)
      end

      it 'RR4: customer removes own mention (self-removal) → 200' do
        expect { delete "/api/v1/mentions/#{mention.id}", as: :json }
          .to change { ticket.mentions.reload.count }.by(-1)

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
