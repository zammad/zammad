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
  let!(:organization_nested) do
    create(:organization, name: 'Tomato42 Ltd.', note: 'Tomato42 Ltd.')
  end
  let!(:customer_user_nested) do
    create(:customer_user, organization: organization_nested)
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
  let!(:ticket_nested) do
    create(:ticket, title: 'vegetable request', customer: customer_user_nested, group: group)
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
  let!(:article_nested) do
    article = create(:ticket_article, ticket_id: ticket_nested.id)

    Store.add(
      object:        'Ticket::Article',
      o_id:          article.id,
      data:          File.binread(Rails.root.join('test/data/elasticsearch/es-normal.txt')),
      filename:      'es-normal.txt',
      preferences:   {},
      created_by_id: 1,
    )

    article
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

    it 'does find the user of the nested organization and also even if the organization name changes' do

      # because of the initial relation between user and organization
      # both user and organization will be found as result
      authenticated_as(agent_user)
      post '/api/v1/search/User', params: { query: 'Tomato42' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Organization'][organization_nested.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][customer_user_nested.id.to_s]).to be_truthy

      post '/api/v1/search/User', params: { query: 'organization:Tomato42' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Organization'][organization_nested.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][customer_user_nested.id.to_s]).to be_truthy

      organization_nested.update(name: 'Cucumber43 Ltd.')
      Scheduler.worker(true)
      SearchIndexBackend.refresh

      # even after a change of the organization name we should find
      # the customer user because of the nested organization data
      post '/api/v1/search/User', params: { query: 'Cucumber43' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Organization'][organization_nested.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][customer_user_nested.id.to_s]).to be_truthy

      post '/api/v1/search/User', params: { query: 'organization:Cucumber43' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Organization'][organization_nested.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][customer_user_nested.id.to_s]).to be_truthy
    end

    it 'does find the ticket by organization name even if the organization name changes' do
      authenticated_as(agent_user)
      post '/api/v1/search/Ticket', params: { query: 'Tomato42' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Organization'][organization_nested.id.to_s]).to be_truthy
      expect(json_response['assets']['Ticket'][ticket_nested.id.to_s]).to be_truthy

      post '/api/v1/search/Ticket', params: { query: 'organization:Tomato42' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Organization'][organization_nested.id.to_s]).to be_truthy
      expect(json_response['assets']['Ticket'][ticket_nested.id.to_s]).to be_truthy

      organization_nested.update(name: 'Cucumber43 Ltd.')
      Scheduler.worker(true)
      SearchIndexBackend.refresh

      post '/api/v1/search/Ticket', params: { query: 'Cucumber43' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Organization'][organization_nested.id.to_s]).to be_truthy
      expect(json_response['assets']['Ticket'][ticket_nested.id.to_s]).to be_truthy

      post '/api/v1/search/Ticket', params: { query: 'organization:Cucumber43' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Organization'][organization_nested.id.to_s]).to be_truthy
      expect(json_response['assets']['Ticket'][ticket_nested.id.to_s]).to be_truthy
    end

    it 'does find the ticket by attachment even after ticket reindex' do
      params = {
        query: 'text66',
        limit: 10,
      }

      authenticated_as(agent_user)
      post '/api/v1/search/Ticket', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Ticket'][ticket_nested.id.to_s]).to be_truthy

      organization_nested.update(name: 'Cucumber43 Ltd.')
      Scheduler.worker(true)
      SearchIndexBackend.refresh

      params = {
        query: 'text66',
        limit: 10,
      }

      post '/api/v1/search/Ticket', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Ticket'][ticket_nested.id.to_s]).to be_truthy
    end
  end
end
