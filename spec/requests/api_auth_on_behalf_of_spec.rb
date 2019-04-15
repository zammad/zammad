require 'rails_helper'

RSpec.describe 'Api Auth On Behalf Of', type: :request do

  let(:admin_user) do
    create(:admin_user, groups: Group.all)
  end
  let(:agent_user) do
    create(:agent_user)
  end
  let(:customer_user) do
    create(:customer_user)
  end

  describe 'request handling' do

    it 'does X-On-Behalf-Of auth - ticket create admin for customer by id' do
      params = {
        title:       'a new ticket #3',
        group:       'Users',
        priority:    '2 normal',
        state:       'new',
        customer_id: customer_user.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(admin_user, on_behalf_of: customer_user.id)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(customer_user.id).to eq(json_response['created_by_id'])
    end

    it 'does X-On-Behalf-Of auth - ticket create admin for customer by login' do
      ActivityStream.cleanup(1.year)

      params = {
        title:       'a new ticket #3',
        group:       'Users',
        priority:    '2 normal',
        state:       'new',
        customer_id: customer_user.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(admin_user, on_behalf_of: customer_user.login)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      json_response_ticket = json_response
      expect(json_response_ticket).to be_a_kind_of(Hash)
      expect(customer_user.id).to eq(json_response_ticket['created_by_id'])

      authenticated_as(admin_user)
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
      expect(customer_user.id).to eq(ticket_created.created_by_id)

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
      expect(customer_user.id).to eq(ticket_created.created_by_id)
    end

    it 'does X-On-Behalf-Of auth - ticket create admin for customer by email' do
      params = {
        title:       'a new ticket #3',
        group:       'Users',
        priority:    '2 normal',
        state:       'new',
        customer_id: customer_user.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(admin_user, on_behalf_of: customer_user.email)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(customer_user.id).to eq(json_response['created_by_id'])
    end

    it 'does X-On-Behalf-Of auth - ticket create admin for unknown' do
      params = {
        title:       'a new ticket #3',
        group:       'Users',
        priority:    '2 normal',
        state:       'new',
        customer_id: customer_user.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(admin_user, on_behalf_of: 99_449_494_949)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unauthorized)
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
        customer_id: customer_user.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(customer_user, on_behalf_of: admin_user.email)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unauthorized)
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
        customer_id: customer_user.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(admin_user, on_behalf_of: customer_user.email)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(@response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No lookup value found for \'group\': "secret1234"')
    end
  end
end
