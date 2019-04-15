require 'rails_helper'

RSpec.describe 'Search', type: :request, searchindex: true do

  let(:group) { create(:group) }
  let!(:admin_user) do
    create(:admin_user, groups: [Group.lookup(name: 'Users'), group])
  end
  let!(:agent_user) do
    create(:agent_user, firstname: 'Search 1234', groups: [Group.lookup(name: 'Users'), group])
  end
  let!(:customer_user) do
    create(:customer_user)
  end
  let!(:organization1) do
    create(:organization, name: 'Rest Org')
  end
  let!(:organization2) do
    create(:organization, name: 'Rest Org #2')
  end
  let!(:organization3) do
    create(:organization, name: 'Rest Org #3')
  end
  let!(:organization4) do
    create(:organization, name: 'Tes.t. Org')
  end
  let!(:organization5) do
    create(:organization, name: 'ABC_D Org')
  end
  let!(:customer_user2) do
    create(:customer_user, organization: organization1)
  end
  let!(:customer_user3) do
    create(:customer_user, organization: organization1)
  end
  let!(:ticket1) do
    create(:ticket, title: 'test 1234-1', customer: customer_user, group: group)
  end
  let!(:ticket2) do
    create(:ticket, title: 'test 1234-2', customer: customer_user2, group: group)
  end
  let!(:ticket3) do
    create(:ticket, title: 'test 1234-2', customer: customer_user3, group: group)
  end
  let!(:article1) do
    create(:ticket_article, ticket_id: ticket1.id)
  end
  let!(:article2) do
    create(:ticket_article, ticket_id: ticket2.id)
  end
  let!(:article3) do
    create(:ticket_article, ticket_id: ticket3.id)
  end

  before do
    configure_elasticsearch do

      travel 1.minute

      rebuild_searchindex

      # execute background jobs
      Scheduler.worker(true)

      sleep 6
    end
  end

  describe 'request handling' do

    it 'does settings index with nobody' do
      params = {
        query: 'test 1234',
        limit: 2,
      }

      post '/api/v1/search/ticket', params: params, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['error']).to eq('authentication failed')

      post '/api/v1/search/user', params: params, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['error']).to eq('authentication failed')

      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does settings index with admin' do
      params = {
        query: '1234*',
        limit: 1,
      }
      authenticated_as(admin_user)
      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket3.id)
      expect(json_response['result'][1]['type']).to eq('User')
      expect(json_response['result'][1]['id']).to eq(agent_user.id)
      expect(json_response['result'][2]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket3.id)
      expect(json_response['result'][1]['type']).to eq('Ticket')
      expect(json_response['result'][1]['id']).to eq(ticket2.id)
      expect(json_response['result'][2]['type']).to eq('Ticket')
      expect(json_response['result'][2]['id']).to eq(ticket1.id)
      expect(json_response['result'][3]['type']).to eq('User')
      expect(json_response['result'][3]['id']).to eq(agent_user.id)
      expect(json_response['result'][4]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search/ticket', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket3.id)
      expect(json_response['result'][1]['type']).to eq('Ticket')
      expect(json_response['result'][1]['id']).to eq(ticket2.id)
      expect(json_response['result'][2]['type']).to eq('Ticket')
      expect(json_response['result'][2]['id']).to eq(ticket1.id)
      expect(json_response['result'][3]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search/user', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['result'][0]['type']).to eq('User')
      expect(json_response['result'][0]['id']).to eq(agent_user.id)
      expect(json_response['result'][1]).to be_falsey
    end

    it 'does settings index with agent' do
      params = {
        query: '1234*',
        limit: 1,
      }

      authenticated_as(agent_user)
      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket3.id)
      expect(json_response['result'][1]['type']).to eq('User')
      expect(json_response['result'][1]['id']).to eq(agent_user.id)
      expect(json_response['result'][2]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket3.id)
      expect(json_response['result'][1]['type']).to eq('Ticket')
      expect(json_response['result'][1]['id']).to eq(ticket2.id)
      expect(json_response['result'][2]['type']).to eq('Ticket')
      expect(json_response['result'][2]['id']).to eq(ticket1.id)
      expect(json_response['result'][3]['type']).to eq('User')
      expect(json_response['result'][3]['id']).to eq(agent_user.id)
      expect(json_response['result'][4]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search/ticket', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket3.id)
      expect(json_response['result'][1]['type']).to eq('Ticket')
      expect(json_response['result'][1]['id']).to eq(ticket2.id)
      expect(json_response['result'][2]['type']).to eq('Ticket')
      expect(json_response['result'][2]['id']).to eq(ticket1.id)
      expect(json_response['result'][3]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search/user', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['result'][0]['type']).to eq('User')
      expect(json_response['result'][0]['id']).to eq(agent_user.id)
      expect(json_response['result'][1]).to be_falsey
    end

    it 'does settings index with customer 1' do
      params = {
        query: '1234*',
        limit: 10,
      }

      authenticated_as(customer_user)
      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket1.id)
      expect(json_response['result'][1]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search/ticket', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket1.id)
      expect(json_response['result'][1]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search/user', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['result'][0]).to be_falsey
    end

    it 'does settings index with customer 2' do
      params = {
        query: '1234*',
        limit: 10,
      }

      authenticated_as(customer_user2)
      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket3.id)
      expect(json_response['result'][1]['type']).to eq('Ticket')
      expect(json_response['result'][1]['id']).to eq(ticket2.id)
      expect(json_response['result'][2]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search/ticket', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket3.id)
      expect(json_response['result'][1]['type']).to eq('Ticket')
      expect(json_response['result'][1]['id']).to eq(ticket2.id)
      expect(json_response['result'][2]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search/user', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['result'][0]).to be_falsey
    end

    # Verify fix for Github issue #2058 - Autocomplete hangs on dot in the new user form
    it 'does searching for organization with a dot in its name' do
      authenticated_as(agent_user)
      get '/api/v1/search/organization?query=tes.', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['result'].size).to eq(1)
      expect(json_response['result'][0]['type']).to eq('Organization')
      target_id = json_response['result'][0]['id']
      expect(json_response['assets']['Organization'][target_id.to_s]['name']).to eq('Tes.t. Org')
    end

    # Search query H& should correctly match H&M
    it 'does searching for organization with _ in its name' do
      authenticated_as(agent_user)
      get '/api/v1/search/organization?query=abc_', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['result'].size).to eq(1)
      expect(json_response['result'][0]['type']).to eq('Organization')
      target_id = json_response['result'][0]['id']
      expect(json_response['assets']['Organization'][target_id.to_s]['name']).to eq('ABC_D Org')
    end
  end
end
