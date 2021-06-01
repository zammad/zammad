# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Api Auth On Behalf Of', type: :request do

  let(:admin) do
    create(:admin, groups: Group.all)
  end
  let(:agent) do
    create(:agent)
  end
  let(:customer) do
    create(:customer, firstname: 'Behalf of')
  end

  describe 'request handling' do

    it 'does X-On-Behalf-Of auth - ticket create admin for customer by id' do
      params = {
        title:       'a new ticket #3',
        group:       'Users',
        priority:    '2 normal',
        state:       'new',
        customer_id: customer.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(admin, on_behalf_of: customer.id)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(customer.id).to eq(json_response['created_by_id'])
    end

    it 'does X-On-Behalf-Of auth - ticket create admin for customer by login (upcase)' do
      params = {
        title:       'a new ticket #3',
        group:       'Users',
        priority:    '2 normal',
        state:       'new',
        customer_id: customer.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(admin, on_behalf_of: customer.login.upcase)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(customer.id).to eq(json_response['created_by_id'])
    end

    it 'does X-On-Behalf-Of auth - ticket create admin for customer by login' do
      ActivityStream.cleanup(1.year)

      params = {
        title:       'a new ticket #3',
        group:       'Users',
        priority:    '2 normal',
        state:       'new',
        customer_id: customer.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(admin, on_behalf_of: customer.login)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      json_response_ticket = json_response
      expect(json_response_ticket).to be_a_kind_of(Hash)
      expect(customer.id).to eq(json_response_ticket['created_by_id'])

      authenticated_as(admin)
      get '/api/v1/activity_stream?full=true', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      json_response_activity = json_response
      expect(json_response_activity).to be_a_kind_of(Hash)

      ticket_created = nil
      json_response_activity['record_ids'].each do |record_id|
        activity_stream = ActivityStream.find(record_id)
        next if activity_stream.object.name != 'Ticket'
        next if activity_stream.o_id != json_response_ticket['id'].to_i

        ticket_created = activity_stream
      end

      expect(ticket_created).to be_truthy
      expect(customer.id).to eq(ticket_created.created_by_id)

      get '/api/v1/activity_stream', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      json_response_activity = json_response
      expect(json_response_activity).to be_a_kind_of(Array)

      ticket_created = nil
      json_response_activity.each do |record|
        activity_stream = ActivityStream.find(record['id'])
        next if activity_stream.object.name != 'Ticket'
        next if activity_stream.o_id != json_response_ticket['id']

        ticket_created = activity_stream
      end

      expect(ticket_created).to be_truthy
      expect(customer.id).to eq(ticket_created.created_by_id)
    end

    it 'does X-On-Behalf-Of auth - ticket create admin for customer by email' do
      params = {
        title:       'a new ticket #3',
        group:       'Users',
        priority:    '2 normal',
        state:       'new',
        customer_id: customer.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(admin, on_behalf_of: customer.email)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(customer.id).to eq(json_response['created_by_id'])
    end

    it 'does X-On-Behalf-Of auth - ticket create admin for unknown' do
      params = {
        title:       'a new ticket #3',
        group:       'Users',
        priority:    '2 normal',
        state:       'new',
        customer_id: customer.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(admin, on_behalf_of: 99_449_494_949)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(@response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq("No such user '99449494949'")
    end

    it 'does X-On-Behalf-Of auth - ticket create customer for admin' do
      params = {
        title:       'a new ticket #3',
        group:       'Users',
        priority:    '2 normal',
        state:       'new',
        customer_id: customer.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(customer, on_behalf_of: admin.email)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(@response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq("Current user has no permission to use 'X-On-Behalf-Of'!")
    end

    it 'does X-On-Behalf-Of auth - ticket create admin for customer by email but no permitted action' do
      params = {
        title:       'a new ticket #3',
        group:       'secret1234',
        priority:    '2 normal',
        state:       'new',
        customer_id: customer.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(admin, on_behalf_of: customer.email)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(@response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No lookup value found for \'group\': "secret1234"')
    end

    context 'when Token Admin has no ticket.* permission' do

      let(:admin) { create(:user, firstname: 'Requester', roles: [admin_user_role]) }

      let(:token) { create(:token, user: admin, permissions: %w[admin.user]) }

      let(:admin_user_role) do
        create(:role).tap { |role| role.permission_grant('admin.user') }
      end

      it 'creates Ticket because of behalf of user permission' do
        params = {
          title:       'a new ticket #3',
          group:       'Users',
          priority:    '2 normal',
          state:       'new',
          customer_id: customer.id,
          article:     {
            body: 'some test 123',
          },
        }
        authenticated_as(admin, on_behalf_of: customer.email, token: token)
        post '/api/v1/tickets', params: params, as: :json
        expect(response).to have_http_status(:created)
        expect(json_response).to be_a_kind_of(Hash)
        expect(customer.id).to eq(json_response['created_by_id'])
      end
    end
  end
end
