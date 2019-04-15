require 'rails_helper'

RSpec.describe 'Organization', type: :request, searchindex: true do

  let!(:admin_user) do
    create(:admin_user, groups: Group.all)
  end
  let!(:agent_user) do
    create(:agent_user, firstname: 'Search 1234', groups: Group.all)
  end
  let!(:customer_user) do
    create(:customer_user)
  end
  let!(:organization) do
    create(
      :organization,
      name:       'Rest Org #1',
      note:       'Rest Org #1',
      created_at: '2017-09-05 10:00:00',
    )
  end
  let!(:organization2) do
    create(
      :organization,
      name:       'Rest Org #2',
      note:       'Rest Org #2',
      created_at: '2017-09-05 11:00:00',
    )
  end
  let!(:organization3) do
    create(
      :organization,
      name:       'Rest Org #3',
      note:       'Rest Org #3',
      created_at: '2017-09-05 12:00:00',
    )
  end
  let!(:customer_user2) do
    create(:customer_user, organization: organization)
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

    it 'does index with agent' do

      # index
      authenticated_as(agent_user)
      get '/api/v1/organizations', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]['member_ids']).to be_a_kind_of(Array)
      expect(json_response.length >= 3).to be_truthy

      get '/api/v1/organizations?limit=40&page=1&per_page=2', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      organizations = Organization.order(:id).limit(2)
      expect(json_response[0]['id']).to eq(organizations[0].id)
      expect(json_response[0]['member_ids']).to eq(organizations[0].member_ids)
      expect(json_response[1]['id']).to eq(organizations[1].id)
      expect(json_response[1]['member_ids']).to eq(organizations[1].member_ids)
      expect(json_response.count).to eq(2)

      get '/api/v1/organizations?limit=40&page=2&per_page=2', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      organizations = Organization.order(:id).limit(4)
      expect(json_response[0]['id']).to eq(organizations[2].id)
      expect(json_response[0]['member_ids']).to eq(organizations[2].member_ids)
      expect(json_response[1]['id']).to eq(organizations[3].id)
      expect(json_response[1]['member_ids']).to eq(organizations[3].member_ids)

      expect(json_response.count).to eq(2)

      # show/:id
      get "/api/v1/organizations/#{organization.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['member_ids']).to be_a_kind_of(Array)
      expect(json_response['members']).to be_falsey
      expect('Rest Org #1').to eq(json_response['name'])

      get "/api/v1/organizations/#{organization2.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['member_ids']).to be_a_kind_of(Array)
      expect(json_response['members']).to be_falsey
      expect('Rest Org #2').to eq(json_response['name'])

      # search as agent
      Scheduler.worker(true)
      get "/api/v1/organizations/search?query=#{CGI.escape('Zammad')}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]['name']).to eq('Zammad Foundation')
      expect(json_response[0]['member_ids']).to be_truthy
      expect(json_response[0]['members']).to be_falsey

      get "/api/v1/organizations/search?query=#{CGI.escape('Zammad')}&expand=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]['name']).to eq('Zammad Foundation')
      expect(json_response[0]['member_ids']).to be_truthy
      expect(json_response[0]['members']).to be_truthy

      get "/api/v1/organizations/search?query=#{CGI.escape('Zammad')}&label=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]['label']).to eq('Zammad Foundation')
      expect(json_response[0]['value']).to eq('Zammad Foundation')
      expect(json_response[0]['member_ids']).to be_falsey
      expect(json_response[0]['members']).to be_falsey
    end

    it 'does index with customer1' do

      # index
      authenticated_as(customer_user)
      get '/api/v1/organizations', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response.length).to eq(0)

      # show/:id
      get "/api/v1/organizations/#{organization.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['name']).to be_nil

      get "/api/v1/organizations/#{organization2.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['name']).to be_nil

      # search
      Scheduler.worker(true)
      get "/api/v1/organizations/search?query=#{CGI.escape('Zammad')}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'does index with customer2' do

      # index
      authenticated_as(customer_user2)
      get '/api/v1/organizations', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response.length).to eq(1)

      # show/:id
      get "/api/v1/organizations/#{organization.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect('Rest Org #1').to eq(json_response['name'])

      get "/api/v1/organizations/#{organization2.id}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['name']).to be_nil

      # search
      Scheduler.worker(true)
      get "/api/v1/organizations/search?query=#{CGI.escape('Zammad')}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'does organization search sortable' do
      authenticated_as(admin_user)
      get "/api/v1/organizations/search?query=#{CGI.escape('Rest Org')}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to be_a_kind_of(Array)
      expect(result).to eq([ organization.id, organization3.id, organization2.id ])

      get "/api/v1/organizations/search?query=#{CGI.escape('Rest Org')}", params: { sort_by: 'created_at', order_by: 'asc' }, as: :json
      expect(response).to have_http_status(:ok)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to be_a_kind_of(Array)
      expect(result).to eq([ organization.id, organization2.id, organization3.id ])

      get "/api/v1/organizations/search?query=#{CGI.escape('Rest Org')}", params: { sort_by: 'note', order_by: 'asc' }, as: :json
      expect(response).to have_http_status(:ok)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to be_a_kind_of(Array)
      expect(result).to eq([ organization.id, organization2.id, organization3.id ])

      get "/api/v1/organizations/search?query=#{CGI.escape('Rest Org')}", params: { sort_by: 'note', order_by: 'desc' }, as: :json
      expect(response).to have_http_status(:ok)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to be_a_kind_of(Array)
      expect(result).to eq([ organization3.id, organization2.id, organization.id ])

      get "/api/v1/organizations/search?query=#{CGI.escape('Rest Org')}", params: { sort_by: %w[note created_at], order_by: %w[desc asc] }, as: :json
      expect(response).to have_http_status(:ok)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to be_a_kind_of(Array)
      expect(result).to eq([ organization3.id, organization2.id, organization.id ])
    end

    it 'does organization show and response format' do
      organization = create(
        :organization,
        name:          'Rest Org NEW',
        members:       [customer_user],
        updated_by_id: admin_user.id,
        created_by_id: admin_user.id,
      )

      authenticated_as(admin_user)
      get "/api/v1/organizations/#{organization.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(organization.id)
      expect(json_response['name']).to eq(organization.name)
      expect(json_response['members']).to be_falsey
      expect(json_response['member_ids']).to eq([customer_user.id])
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      get "/api/v1/organizations/#{organization.id}?expand=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(organization.id)
      expect(json_response['name']).to eq(organization.name)
      expect(json_response['members']).to be_truthy
      expect(json_response['member_ids']).to eq([customer_user.id])
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      get "/api/v1/organizations/#{organization.id}?expand=false", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(organization.id)
      expect(json_response['name']).to eq(organization.name)
      expect(json_response['members']).to be_falsey
      expect(json_response['member_ids']).to eq([customer_user.id])
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      get "/api/v1/organizations/#{organization.id}?full=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(organization.id)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Organization']).to be_truthy
      expect(json_response['assets']['Organization'][organization.id.to_s]).to be_truthy
      expect(json_response['assets']['Organization'][organization.id.to_s]['id']).to eq(organization.id)
      expect(json_response['assets']['Organization'][organization.id.to_s]['name']).to eq(organization.name)
      expect(json_response['assets']['Organization'][organization.id.to_s]['member_ids']).to eq(organization.member_ids)
      expect(json_response['assets']['Organization'][organization.id.to_s]['members']).to be_falsey

      get "/api/v1/organizations/#{organization.id}?full=false", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(organization.id)
      expect(json_response['name']).to eq(organization.name)
      expect(json_response['members']).to be_falsey
      expect(json_response['member_ids']).to eq([customer_user.id])
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)
    end

    it 'does organization index and response format' do
      organization = create(
        :organization,
        name:          'Rest Org NEW',
        members:       [customer_user],
        updated_by_id: admin_user.id,
        created_by_id: admin_user.id,
      )

      authenticated_as(admin_user)
      get '/api/v1/organizations', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0].class).to eq(Hash)
      expect(json_response.last['id']).to eq(organization.id)
      expect(json_response.last['name']).to eq(organization.name)
      expect(json_response.last['members']).to be_falsey
      expect(json_response.last['member_ids']).to eq(organization.member_ids)
      expect(json_response.last['updated_by_id']).to eq(admin_user.id)
      expect(json_response.last['created_by_id']).to eq(admin_user.id)

      get '/api/v1/organizations?expand=true', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0].class).to eq(Hash)
      expect(json_response.last['id']).to eq(organization.id)
      expect(json_response.last['name']).to eq(organization.name)
      expect(json_response.last['member_ids']).to eq(organization.member_ids)
      expect([customer_user.login]).to eq(organization.members.pluck(:login))
      expect(json_response.last['updated_by_id']).to eq(admin_user.id)
      expect(json_response.last['created_by_id']).to eq(admin_user.id)

      get '/api/v1/organizations?expand=false', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0].class).to eq(Hash)
      expect(json_response.last['id']).to eq(organization.id)
      expect(json_response.last['name']).to eq(organization.name)
      expect(json_response.last['members']).to be_falsey
      expect(json_response.last['member_ids']).to eq(organization.member_ids)
      expect(json_response.last['updated_by_id']).to eq(admin_user.id)
      expect(json_response.last['created_by_id']).to eq(admin_user.id)

      get '/api/v1/organizations?full=true', params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['record_ids'].class).to eq(Array)
      expect(json_response['record_ids'][0]).to eq(1)
      expect(json_response['record_ids'].last).to eq(organization.id)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Organization']).to be_truthy
      expect(json_response['assets']['Organization'][organization.id.to_s]).to be_truthy
      expect(json_response['assets']['Organization'][organization.id.to_s]['id']).to eq(organization.id)
      expect(json_response['assets']['Organization'][organization.id.to_s]['name']).to eq(organization.name)
      expect(json_response['assets']['Organization'][organization.id.to_s]['member_ids']).to eq(organization.member_ids)
      expect(json_response['assets']['Organization'][organization.id.to_s]['members']).to be_falsey

      get '/api/v1/organizations?full=false', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0].class).to eq(Hash)
      expect(json_response.last['id']).to eq(organization.id)
      expect(json_response.last['name']).to eq(organization.name)
      expect(json_response.last['members']).to be_falsey
      expect(json_response.last['member_ids']).to eq(organization.member_ids)
      expect(json_response.last['updated_by_id']).to eq(admin_user.id)
      expect(json_response.last['created_by_id']).to eq(admin_user.id)
    end

    it 'does ticket create and response format' do
      params = {
        name:    'Rest Org NEW',
        members: [customer_user.login],
      }

      authenticated_as(admin_user)
      post '/api/v1/organizations', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)

      organization = Organization.find(json_response['id'])
      expect(json_response['name']).to eq(organization.name)
      expect(json_response['member_ids']).to eq(organization.member_ids)
      expect(json_response['members']).to be_falsey
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      params[:name] = 'Rest Org NEW #2'
      post '/api/v1/organizations?expand=true', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)

      organization = Organization.find(json_response['id'])
      expect(json_response['name']).to eq(organization.name)
      expect(json_response['member_ids']).to eq(organization.member_ids)
      expect(json_response['members']).to eq(organization.members.pluck(:login))
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      params[:name] = 'Rest Org NEW #3'
      post '/api/v1/organizations?full=true', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)

      organization = Organization.find(json_response['id'])
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Organization']).to be_truthy
      expect(json_response['assets']['Organization'][organization.id.to_s]).to be_truthy
      expect(json_response['assets']['Organization'][organization.id.to_s]['id']).to eq(organization.id)
      expect(json_response['assets']['Organization'][organization.id.to_s]['name']).to eq(organization.name)
      expect(json_response['assets']['Organization'][organization.id.to_s]['member_ids']).to eq(organization.member_ids)
      expect(json_response['assets']['Organization'][organization.id.to_s]['members']).to be_falsey

    end

    it 'does ticket update and response formats' do
      organization = create(
        :organization,
        name:          'Rest Org NEW',
        members:       [customer_user],
        updated_by_id: admin_user.id,
        created_by_id: admin_user.id,
      )

      params = {
        name: 'a update name #1',
      }
      authenticated_as(admin_user)
      put "/api/v1/organizations/#{organization.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      organization = Organization.find(json_response['id'])
      expect(json_response['name']).to eq(params[:name])
      expect(json_response['member_ids']).to eq(organization.member_ids)
      expect(json_response['members']).to be_falsey
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      params = {
        name: 'a update name #2',
      }
      put "/api/v1/organizations/#{organization.id}?expand=true", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      organization = Organization.find(json_response['id'])
      expect(json_response['name']).to eq(params[:name])
      expect(json_response['member_ids']).to eq(organization.member_ids)
      expect([customer_user.login]).to eq(organization.members.pluck(:login))
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      params = {
        name: 'a update name #3',
      }
      put "/api/v1/organizations/#{organization.id}?full=true", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      organization = Organization.find(json_response['id'])
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Organization']).to be_truthy
      expect(json_response['assets']['Organization'][organization.id.to_s]).to be_truthy
      expect(json_response['assets']['Organization'][organization.id.to_s]['id']).to eq(organization.id)
      expect(json_response['assets']['Organization'][organization.id.to_s]['name']).to eq(params[:name])
      expect(json_response['assets']['Organization'][organization.id.to_s]['member_ids']).to eq(organization.member_ids)
      expect(json_response['assets']['Organization'][organization.id.to_s]['members']).to be_falsey

    end

    it 'does organization history' do
      organization1 = create(
        :organization,
        name: 'some org',
      )

      authenticated_as(agent_user)
      get "/api/v1/organizations/history/#{organization1.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['history'].class).to eq(Array)
      expect(json_response['assets'].class).to eq(Hash)
      expect(json_response['assets']['Ticket']).to be_nil
      expect(json_response['assets']['Organization'][organization1.id.to_s]).not_to be_nil
    end

    it 'does csv example - customer no access' do
      authenticated_as(customer_user)
      get '/api/v1/organizations/import_example', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Not authorized (user)!')
    end

    it 'does csv example - admin access' do
      authenticated_as(admin_user)
      get '/api/v1/organizations/import_example', params: {}, as: :json
      expect(response).to have_http_status(:ok)

      rows = CSV.parse(@response.body)
      header = rows.shift

      expect(header[0]).to eq('id')
      expect(header[1]).to eq('name')
      expect(header[2]).to eq('shared')
      expect(header[3]).to eq('domain')
      expect(header[4]).to eq('domain_assignment')
      expect(header[5]).to eq('active')
      expect(header[6]).to eq('note')
      expect(header).to include('members')
    end

    it 'does csv import - admin access' do

      UserInfo.current_user_id = 1
      customer1 = create(
        :customer_user,
        login:     'customer1-members@example.com',
        firstname: 'Member',
        lastname:  'Customer',
        email:     'customer1-members@example.com',
        password:  'customerpw',
        active:    true,
      )
      customer2 = create(
        :customer_user,
        login:     'customer2-members@example.com',
        firstname: 'Member',
        lastname:  'Customer',
        email:     'customer2-members@example.com',
        password:  'customerpw',
        active:    true,
      )
      UserInfo.current_user_id = nil

      # invalid file
      authenticated_as(admin_user)
      csv_file = fixture_file_upload('csv_import/organization/simple_col_not_existing.csv', 'text/csv')
      post '/api/v1/organizations/import?try=true', params: { file: csv_file, col_sep: ';' }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['try']).to eq(true)
      expect(json_response['records'].count).to eq(2)
      expect(json_response['result']).to eq('failed')
      expect(json_response['errors'].count).to eq(2)
      expect(json_response['errors'][0]).to eq("Line 1: Unable to create record - unknown attribute 'name2' for Organization.")
      expect(json_response['errors'][1]).to eq("Line 2: Unable to create record - unknown attribute 'name2' for Organization.")

      # valid file try
      csv_file = fixture_file_upload('csv_import/organization/simple.csv', 'text/csv')
      post '/api/v1/organizations/import?try=true', params: { file: csv_file, col_sep: ';' }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['try']).to eq(true)
      expect(json_response['records'].count).to eq(2)
      expect(json_response['result']).to eq('success')

      expect(Organization.find_by(name: 'organization-member-import1')).to be_nil
      expect(Organization.find_by(name: 'organization-member-import2')).to be_nil

      # valid file
      csv_file = fixture_file_upload('csv_import/organization/simple.csv', 'text/csv')
      post '/api/v1/organizations/import', params: { file: csv_file, col_sep: ';' }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['try']).to eq(false)
      expect(json_response['records'].count).to eq(2)
      expect(json_response['result']).to eq('success')

      organization1 = Organization.find_by(name: 'organization-member-import1')
      expect(organization1).to be_truthy
      expect(organization1.name).to eq('organization-member-import1')
      expect(organization1.members.count).to eq(1)
      expect(organization1.members.first.login).to eq(customer1.login)
      expect(organization1.active).to eq(true)
      organization2 = Organization.find_by(name: 'organization-member-import2')
      expect(organization2).to be_truthy
      expect(organization2.name).to eq('organization-member-import2')
      expect(organization2.members.count).to eq(1)
      expect(organization2.members.first.login).to eq(customer2.login)
      expect(organization2.active).to eq(false)
    end
  end
end
