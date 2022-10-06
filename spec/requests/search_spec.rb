# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Search', type: :request do

  let(:group) { create(:group) }
  let!(:admin) do
    create(:admin, groups: [Group.lookup(name: 'Users'), group])
  end
  let!(:agent) do
    create(:agent, firstname: 'Search 1234', groups: [Group.lookup(name: 'Users'), group])
  end
  let!(:customer) do
    create(:customer)
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
  let!(:customer2) do
    create(:customer, organization: organization1)
  end
  let!(:customer3) do
    create(:customer, organization: organization1)
  end
  let!(:ticket1) do
    create(:ticket, title: 'test 1234-1', customer: customer, group: group)
  end
  let!(:ticket2) do
    create(:ticket, title: 'test 1234-2', customer: customer2, group: group)
  end
  let!(:ticket3) do
    create(:ticket, title: 'test 1234-2', customer: customer3, group: group)
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

  describe 'request handling', searchindex: true, performs_jobs: true do
    before do
      searchindex_model_reload([::Ticket, ::User, ::Organization])
    end

    it 'does settings index with nobody' do
      params = {
        query: 'test 1234',
        limit: 2,
      }

      post '/api/v1/search/ticket', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['error']).to eq('Authentication required')

      post '/api/v1/search/user', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['error']).to eq('Authentication required')

      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['error']).to eq('Authentication required')
    end

    it 'does settings index with admin' do
      params = {
        query: '1234*',
        limit: 1,
      }
      authenticated_as(admin)
      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket3.id)
      expect(json_response['result'][1]['type']).to eq('User')
      expect(json_response['result'][1]['id']).to eq(agent.id)
      expect(json_response['result'][2]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket3.id)
      expect(json_response['result'][1]['type']).to eq('Ticket')
      expect(json_response['result'][1]['id']).to eq(ticket2.id)
      expect(json_response['result'][2]['type']).to eq('Ticket')
      expect(json_response['result'][2]['id']).to eq(ticket1.id)
      expect(json_response['result'][3]['type']).to eq('User')
      expect(json_response['result'][3]['id']).to eq(agent.id)
      expect(json_response['result'][4]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search/ticket', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
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
      expect(json_response).to be_a(Hash)
      expect(json_response['result'][0]['type']).to eq('User')
      expect(json_response['result'][0]['id']).to eq(agent.id)
      expect(json_response['result'][1]).to be_falsey
    end

    it 'does settings index with agent' do
      params = {
        query: '1234*',
        limit: 1,
      }

      authenticated_as(agent)
      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket3.id)
      expect(json_response['result'][1]['type']).to eq('User')
      expect(json_response['result'][1]['id']).to eq(agent.id)
      expect(json_response['result'][2]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
      expect(json_response['result'][0]['type']).to eq('Ticket')
      expect(json_response['result'][0]['id']).to eq(ticket3.id)
      expect(json_response['result'][1]['type']).to eq('Ticket')
      expect(json_response['result'][1]['id']).to eq(ticket2.id)
      expect(json_response['result'][2]['type']).to eq('Ticket')
      expect(json_response['result'][2]['id']).to eq(ticket1.id)
      expect(json_response['result'][3]['type']).to eq('User')
      expect(json_response['result'][3]['id']).to eq(agent.id)
      expect(json_response['result'][4]).to be_falsey

      params = {
        query: '1234*',
        limit: 10,
      }

      post '/api/v1/search/ticket', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
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
      expect(json_response).to be_a(Hash)
      expect(json_response['result'][0]['type']).to eq('User')
      expect(json_response['result'][0]['id']).to eq(agent.id)
      expect(json_response['result'][1]).to be_falsey
    end

    it 'does settings index with customer 1' do
      params = {
        query: '1234*',
        limit: 10,
      }

      authenticated_as(customer)
      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
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
      expect(json_response).to be_a(Hash)
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
      expect(json_response).to be_a(Hash)
      expect(json_response['result'][0]).to be_falsey
    end

    it 'does settings index with customer 2' do
      params = {
        query: '1234*',
        limit: 10,
      }

      authenticated_as(customer2)
      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
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
      expect(json_response).to be_a(Hash)
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
      expect(json_response).to be_a(Hash)
      expect(json_response['result'][0]).to be_falsey
    end

    # Verify fix for Github issue #2058 - Autocomplete hangs on dot in the new user form
    it 'does searching for organization with a dot in its name' do
      authenticated_as(agent)
      get '/api/v1/search/organization?query=tes.', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['result'].size).to eq(1)
      expect(json_response['result'][0]['type']).to eq('Organization')
      target_id = json_response['result'][0]['id']
      expect(json_response['assets']['Organization'][target_id.to_s]['name']).to eq('Tes.t. Org')
    end

    # Search query H& should correctly match H&M
    it 'does searching for organization with _ in its name' do
      authenticated_as(agent)
      get '/api/v1/search/organization?query=abc_', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['result'].size).to eq(1)
      expect(json_response['result'][0]['type']).to eq('Organization')
      target_id = json_response['result'][0]['id']
      expect(json_response['assets']['Organization'][target_id.to_s]['name']).to eq('ABC_D Org')
    end

    it 'does find the ticket by group name even if the group name changes' do
      authenticated_as(agent)
      post '/api/v1/search/Ticket', params: { query: "number:#{ticket1.number} && group.name:ultrasupport" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Ticket']).to be_falsey
      expect(group).not_to eq('ultrasupport')

      group.update(name: 'ultrasupport')
      perform_enqueued_jobs
      SearchIndexBackend.refresh

      post '/api/v1/search/Ticket', params: { query: "number:#{ticket1.number} && group.name:ultrasupport" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Ticket'][ticket1.id.to_s]).to be_truthy
    end

    it 'does find the ticket by state name even if the state name changes' do
      authenticated_as(agent)
      post '/api/v1/search/Ticket', params: { query: "number:#{ticket1.number} && state.name:ultrastate" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Ticket']).to be_falsey
      expect(ticket1.state.name).not_to eq('ultrastate')

      ticket1.state.update(name: 'ultrastate')
      perform_enqueued_jobs
      SearchIndexBackend.refresh

      post '/api/v1/search/Ticket', params: { query: "number:#{ticket1.number} && state.name:ultrastate" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Ticket'][ticket1.id.to_s]).to be_truthy
    end

    it 'does find the ticket by priority name even if the priority name changes' do
      authenticated_as(agent)
      post '/api/v1/search/Ticket', params: { query: "number:#{ticket1.number} && priority.name:ultrapriority" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Ticket']).to be_falsey
      expect(ticket1.priority.name).not_to eq('ultrapriority')

      ticket1.priority.update(name: 'ultrapriority')
      perform_enqueued_jobs
      SearchIndexBackend.refresh

      post '/api/v1/search/Ticket', params: { query: "number:#{ticket1.number} && priority.name:ultrapriority" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
      expect(json_response['assets']['Ticket'][ticket1.id.to_s]).to be_truthy
    end
  end

  describe 'Assign user to multiple organizations #1573' do
    shared_examples 'search for organization ids' do
      context 'when customer with multi organizations', authenticated_as: :customer do
        context 'with multi organizations' do
          let(:customer) { create(:customer, organization: organizations[0], organizations: organizations[1..2]) }
          let(:organizations) { create_list(:organization, 5) }

          it 'does not return organizations which are not allowed' do
            params = {
              query: 'TestOrganization',
              limit: 10,
            }
            post '/api/v1/search/Organization', params: params, as: :json
            expect(json_response['result']).to include({ 'id' => organizations[0].id, 'type' => 'Organization' })
            expect(json_response['result']).to include({ 'id' => organizations[1].id, 'type' => 'Organization' })
            expect(json_response['result']).to include({ 'id' => organizations[2].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[3].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[4].id, 'type' => 'Organization' })
          end

          it 'does not return organizations which are not allowed when overwritten' do
            params = {
              query: 'TestOrganization',
              limit: 10,
              ids:   organizations.map(&:id)
            }
            post '/api/v1/search/Organization', params: params, as: :json
            expect(json_response['result']).to include({ 'id' => organizations[0].id, 'type' => 'Organization' })
            expect(json_response['result']).to include({ 'id' => organizations[1].id, 'type' => 'Organization' })
            expect(json_response['result']).to include({ 'id' => organizations[2].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[3].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[4].id, 'type' => 'Organization' })
          end
        end

        context 'with single organization' do
          let(:customer) { create(:customer, organization: organizations[0]) }
          let(:organizations) { create_list(:organization, 5) }

          it 'does not return organizations which are not allowed' do
            params = {
              query: 'TestOrganization',
              limit: 10,
            }
            post '/api/v1/search/Organization', params: params, as: :json
            expect(json_response['result']).to include({ 'id' => organizations[0].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[1].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[2].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[3].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[4].id, 'type' => 'Organization' })
          end

          it 'does not return organizations which are not allowed when overwritten' do
            params = {
              query: 'TestOrganization',
              limit: 10,
              ids:   organizations.map(&:id)
            }
            post '/api/v1/search/Organization', params: params, as: :json
            expect(json_response['result']).to include({ 'id' => organizations[0].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[1].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[2].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[3].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[4].id, 'type' => 'Organization' })
          end
        end

        context 'with no organization' do
          let(:customer) do
            organizations
            create(:customer)
          end
          let(:organizations) { create_list(:organization, 5) }

          it 'does not return organizations which are not allowed' do
            params = {
              query: 'TestOrganization',
              limit: 10,
            }
            post '/api/v1/search/Organization', params: params, as: :json
            expect(json_response['result']).not_to include({ 'id' => organizations[0].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[1].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[2].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[3].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[4].id, 'type' => 'Organization' })
          end

          it 'does not return organizations which are not allowed when overwritten' do
            params = {
              query: 'TestOrganization',
              limit: 10,
              ids:   organizations.map(&:id)
            }
            post '/api/v1/search/Organization', params: params, as: :json
            expect(json_response['result']).not_to include({ 'id' => organizations[0].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[1].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[2].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[3].id, 'type' => 'Organization' })
            expect(json_response['result']).not_to include({ 'id' => organizations[4].id, 'type' => 'Organization' })
          end
        end
      end

      it 'does return all organizations' do
        params = {
          query: 'Rest',
          limit: 10,
        }
        authenticated_as(admin)
        post '/api/v1/search/Organization', params: params, as: :json
        expect(json_response['result']).to include({ 'id' => organization1.id, 'type' => 'Organization' })
        expect(json_response['result']).to include({ 'id' => organization2.id, 'type' => 'Organization' })
        expect(json_response['result']).to include({ 'id' => organization3.id, 'type' => 'Organization' })
      end

      it 'does return organization specific ids' do
        params = {
          query: 'Rest',
          ids:   [organization1.id],
          limit: 10,
        }
        authenticated_as(admin)
        post '/api/v1/search/Organization', params: params, as: :json
        expect(json_response['result']).to include({ 'id' => organization1.id, 'type' => 'Organization' })
        expect(json_response['result']).not_to include({ 'id' => organization2.id, 'type' => 'Organization' })
        expect(json_response['result']).not_to include({ 'id' => organization3.id, 'type' => 'Organization' })
      end
    end

    context 'with elasticsearch', searchindex: true do
      before do
        searchindex_model_reload([::Ticket, ::User, ::Organization])
      end

      include_examples 'search for organization ids'
    end

    context 'with db only', searchindex: false do
      before do
        Setting.set('es_url', nil)
      end

      include_examples 'search for organization ids'
    end
  end
end
