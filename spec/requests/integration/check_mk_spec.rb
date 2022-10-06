# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Integration Check MK', type: :request do
  let(:customer) do
    create(:customer)
  end
  let(:group) do
    create(:group)
  end

  before do
    token = SecureRandom.urlsafe_base64(16)
    Setting.set('check_mk_token', token)
    Setting.set('check_mk_integration', true)
  end

  describe 'request handling' do

    it 'does fail without a token' do
      post '/api/v1/integration/check_mk/', params: {}
      expect(response).to have_http_status(:not_found)
    end

    it 'does fail with invalid token and feature enabled' do
      post '/api/v1/integration/check_mk/invalid_token', params: {}
      expect(response).to have_http_status(:unprocessable_entity)

      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('The provided token is invalid.')
    end

    context 'service check' do
      it 'does create ticket with customer email' do
        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
          service:  'some service',
          customer: customer.email,
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_id']).to be_truthy
        expect(json_response['ticket_number']).to be_truthy

        ticket = Ticket.find(json_response['ticket_id'])
        expect(ticket.state.name).to eq('new')
        expect(ticket.customer.email).to eq(customer.email)
        expect(ticket.articles.count).to eq(1)
      end

      it 'does create ticket with customer login' do
        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
          service:  'some service',
          customer: customer.login,
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_id']).to be_truthy
        expect(json_response['ticket_number']).to be_truthy

        ticket = Ticket.find(json_response['ticket_id'])
        expect(ticket.state.name).to eq('new')
        expect(ticket.customer.email).to eq(customer.email)
        expect(ticket.articles.count).to eq(1)
      end

      it 'does create ticket with group' do
        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
          service:  'some service',
          group:    group.name,
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_id']).to be_truthy
        expect(json_response['ticket_number']).to be_truthy

        ticket = Ticket.find(json_response['ticket_id'])
        expect(ticket.state.name).to eq('new')
        expect(ticket.group.name).to eq(group.name)
        expect(ticket.articles.count).to eq(1)
      end

      it 'does create ticket with extra field', db_strategy: :reset do
        create :object_manager_attribute_text, name: 'text1'
        ObjectManager::Attribute.migration_execute

        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
          service:  'some service',
          text1:    'some text'
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_id']).to be_truthy
        expect(json_response['ticket_number']).to be_truthy

        ticket = Ticket.find(json_response['ticket_id'])
        expect(ticket.state.name).to eq('new')
        expect(ticket.text1).to eq('some text')
      end

      it 'does create and close a ticket' do
        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
          service:  'some service',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_id']).to be_truthy
        expect(json_response['ticket_number']).to be_truthy

        ticket = Ticket.find(json_response['ticket_id'])
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(1)

        params = {
          event_id: '123',
          state:    'up',
          host:     'some host',
          service:  'some service',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).not_to be_empty
        expect(json_response['ticket_ids']).to include(ticket.id)

        ticket.reload
        expect(ticket.state.name).to eq('closed')
        expect(ticket.articles.count).to eq(2)
      end

      it 'does double create and auto close' do
        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
          service:  'some service',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_id']).to be_truthy
        expect(json_response['ticket_number']).to be_truthy

        ticket = Ticket.find(json_response['ticket_id'])
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(1)

        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
          service:  'some service',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to eq('ticket already open, added note')
        expect(json_response['ticket_ids']).to include(ticket.id)

        ticket.reload
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(2)

        params = {
          event_id: '123',
          state:    'up',
          host:     'some host',
          service:  'some service',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_ids']).to include(ticket.id)

        ticket.reload
        expect(ticket.state.name).to eq('closed')
        expect(ticket.articles.count).to eq(3)
      end

      it 'does ticket close which get ignored' do
        params = {
          event_id: '123',
          state:    'up',
          host:     'some host',
          service:  'some service',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to eq('no open tickets found, ignore action')
      end

      it 'does double create and no auto close' do
        Setting.set('check_mk_auto_close', false)
        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
          service:  'some service',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_id']).to be_truthy
        expect(json_response['ticket_number']).to be_truthy

        ticket = Ticket.find(json_response['ticket_id'])
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(1)

        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
          service:  'some service',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to eq('ticket already open, added note')
        expect(json_response['ticket_ids']).to include(ticket.id)

        ticket.reload
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(2)

        params = {
          event_id: '123',
          state:    'up',
          host:     'some host',
          service:  'some service',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to eq('ticket already open, added note')
        expect(json_response['ticket_ids']).to include(ticket.id)

        ticket.reload
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(3)
      end

      it 'does double create and auto close - with host recover' do
        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
          service:  'some service',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_id']).to be_truthy
        expect(json_response['ticket_number']).to be_truthy

        ticket = Ticket.find(json_response['ticket_id'])
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(1)

        params = {
          event_id: '123',
          state:    'up',
          host:     'some host',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to eq('no open tickets found, ignore action')
        expect(json_response['ticket_ids']).to be_nil

        ticket.reload
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(1)
      end
    end

    context 'host check' do
      it 'does create and close a ticket' do
        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_id']).to be_truthy
        expect(json_response['ticket_number']).to be_truthy

        ticket = Ticket.find(json_response['ticket_id'])
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(1)

        params = {
          event_id: '123',
          state:    'up',
          host:     'some host',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).not_to be_empty
        expect(json_response['ticket_ids']).to include(ticket.id)

        ticket.reload
        expect(ticket.state.name).to eq('closed')
        expect(ticket.articles.count).to eq(2)
      end

      it 'does double create and auto close' do
        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_id']).to be_truthy
        expect(json_response['ticket_number']).to be_truthy

        ticket = Ticket.find(json_response['ticket_id'])
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(1)

        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to eq('ticket already open, added note')
        expect(json_response['ticket_ids']).to include(ticket.id)

        ticket.reload
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(2)

        params = {
          event_id: '123',
          state:    'up',
          host:     'some host',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_ids']).to include(ticket.id)

        ticket.reload
        expect(ticket.state.name).to eq('closed')
        expect(ticket.articles.count).to eq(3)
      end

      it 'does ticket close which get ignored' do
        params = {
          event_id: '123',
          state:    'up',
          host:     'some host',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to eq('no open tickets found, ignore action')
      end

      it 'does double create and no auto close' do
        Setting.set('check_mk_auto_close', false)
        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_id']).to be_truthy
        expect(json_response['ticket_number']).to be_truthy

        ticket = Ticket.find(json_response['ticket_id'])
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(1)

        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to eq('ticket already open, added note')
        expect(json_response['ticket_ids']).to include(ticket.id)

        ticket.reload
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(2)

        params = {
          event_id: '123',
          state:    'up',
          host:     'some host',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to eq('ticket already open, added note')
        expect(json_response['ticket_ids']).to include(ticket.id)

        ticket.reload
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(3)
      end

      it 'does double create and auto close - with service recover' do
        params = {
          event_id: '123',
          state:    'down',
          host:     'some host',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to be_truthy
        expect(json_response['ticket_id']).to be_truthy
        expect(json_response['ticket_number']).to be_truthy

        ticket = Ticket.find(json_response['ticket_id'])
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(1)

        params = {
          event_id: '123',
          state:    'up',
          host:     'some host',
          service:  'some service',
        }
        post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params: params
        expect(response).to have_http_status(:ok)

        expect(json_response).to be_a(Hash)
        expect(json_response['result']).to eq('no open tickets found, ignore action')
        expect(json_response['ticket_ids']).to be_nil

        ticket.reload
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(1)
      end
    end
  end

end
