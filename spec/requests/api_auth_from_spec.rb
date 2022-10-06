# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Api Auth From', type: :request do

  let(:admin) do
    create(:admin, groups: Group.all)
  end
  let(:agent) do
    create(:agent)
  end
  let(:customer) do
    create(:customer, firstname: 'From')
  end

  describe 'request handling' do

    it 'does From auth - ticket create admin for customer by id' do
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
      authenticated_as(admin, from: customer.id)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(customer.id).to eq(json_response['created_by_id'])
    end

    it 'does From auth - ticket create admin for customer by login (upcase)' do
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
      authenticated_as(admin, from: customer.login.upcase)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(customer.id).to eq(json_response['created_by_id'])
    end

    it 'does From auth - ticket create admin for customer by login' do
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
      authenticated_as(admin, from: customer.login)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      json_response_ticket = json_response
      expect(json_response_ticket).to be_a(Hash)
      expect(customer.id).to eq(json_response_ticket['created_by_id'])

      authenticated_as(admin)
      get '/api/v1/activity_stream?full=true', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      json_response_activity = json_response
      expect(json_response_activity).to be_a(Hash)

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
      expect(json_response_activity).to be_a(Array)

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

    it 'does From auth - ticket create admin for customer by email' do
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
      authenticated_as(admin, from: customer.email)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(customer.id).to eq(json_response['created_by_id'])
    end

    it 'does From auth - ticket create admin for unknown' do
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
      authenticated_as(admin, from: 99_449_494_949)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(@response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq("No such user '99449494949'")
    end

    it 'does From auth - ticket create customer for admin' do
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
      authenticated_as(customer, from: admin.email)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(@response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq("Current user has no permission to use 'From'/'X-On-Behalf-Of'!")
    end

    it 'does From auth - ticket create admin for customer by email but no permitted action' do
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
      authenticated_as(admin, from: customer.email)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(@response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a(Hash)
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
        authenticated_as(admin, from: customer.email, token: token)
        post '/api/v1/tickets', params: params, as: :json
        expect(response).to have_http_status(:created)
        expect(json_response).to be_a(Hash)
        expect(customer.id).to eq(json_response['created_by_id'])
      end
    end

    context 'when customer account has device user permission' do
      let(:customer_user_devices_role) do
        create(:role).tap { |role| role.permission_grant('user_preferences.device') }
      end

      let(:customer) do
        create(:customer, firstname: 'Behalf of', role_ids: Role.signup_role_ids.push(customer_user_devices_role.id))
      end

      it 'creates Ticket because of behalf of customer user, which should not trigger a new user device', performs_jobs: true do
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
        authenticated_as(admin, from: customer.email)
        post '/api/v1/tickets', params: params, as: :json
        expect(response).to have_http_status(:created)
        expect(customer.id).to eq(json_response['created_by_id'])

        expect { perform_enqueued_jobs }.not_to change(UserDevice, :count)
      end
    end
  end

  describe 'user lookup' do
    it 'does From auth - user lookup by ID' do
      authenticated_as(admin, from: customer.id)
      get '/api/v1/users/me', as: :json
      expect(json_response.fetch('id')).to be customer.id
    end

    it 'does From auth - user lookup by login' do
      authenticated_as(admin, from: customer.login)
      get '/api/v1/users/me', as: :json
      expect(json_response.fetch('id')).to be customer.id
    end

    it 'does From auth - user lookup by email' do
      authenticated_as(admin, from: customer.email)
      get '/api/v1/users/me', as: :json
      expect(json_response.fetch('id')).to be customer.id
    end

    # https://github.com/zammad/zammad/issues/2851
    it 'does From auth - user lookup by email even if email starts with a digit' do
      customer.update! email: "#{agent.id}#{customer.email}"

      authenticated_as(admin, from: customer.email)
      get '/api/v1/users/me', as: :json
      expect(json_response.fetch('id')).to be customer.id
    end
  end
end
