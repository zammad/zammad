# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket', type: :request do

  let!(:ticket_group) do
    create(:group, email_address: create(:email_address) )
  end
  let!(:ticket_group_without_create) do
    create(:group, email_address: create(:email_address) )
  end
  let(:admin) do
    create(:admin, groups: Group.all, firstname: 'Tickets', lastname: 'Admin')
  end
  let!(:agent) do
    create(:agent, groups: Group.all, firstname: 'Tickets', lastname: 'Agent')
  end
  let!(:agent_change_only) do
    user = create(:agent, groups: Group.all, firstname: 'Tickets', lastname: 'Agent')
    user.group_names_access_map = {
      ticket_group_without_create.name => %w[read change],
    }
    user
  end
  let!(:customer) do
    create(
      :customer,
      login:     'tickets-customer1@example.com',
      firstname: 'Tickets',
      lastname:  'Customer1',
      email:     'tickets-customer1@example.com',
    )
  end

  describe 'request handling' do

    it 'does ticket create with agent - missing group (01.01)' do
      params = {
        title:   'a new ticket #1',
        article: {
          content_type: 'text/plain', # or text/html
          body:         'some body',
          sender:       'Customer',
          type:         'note',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error_human']).to eq('Group can\'t be blank')
    end

    it 'does ticket create with agent - wrong group (01.02)' do
      params = {
        title:   'a new ticket #2',
        group:   'not_existing',
        article: {
          content_type: 'text/plain', # or text/html
          body:         'some body',
          sender:       'Customer',
          type:         'note',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No lookup value found for \'group\': "not_existing"')
    end

    it 'does ticket create with agent - valid group but no create permissions (01.02a)' do
      params = {
        title:       'a new ticket #1',
        group:       ticket_group_without_create.name,
        priority:    '2 normal',
        state:       'new',
        customer_id: customer.id,
        article:     {
          content_type: 'text/plain', # or text/html
          body:         'some body',
          sender:       'Customer',
          type:         'note',
        },
      }
      authenticated_as(agent_change_only)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized')
    end

    it 'does ticket create with agent - missing article.body (01.03)' do
      params = {
        title:       'a new ticket #3',
        group:       ticket_group.name,
        priority:    '2 normal',
        state:       'new',
        customer_id: customer.id,
        article:     {},
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Need at least article: { body: "some text" }')
    end

    it 'does ticket create with agent - minimal article (01.03)' do
      params = {
        title:       'a new ticket #3',
        group:       ticket_group.name,
        priority:    '2 normal',
        state:       'new',
        customer_id: customer.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #3')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
    end

    it 'does ticket create with agent - minimal article and customer.email (01.04)' do
      params = {
        title:    'a new ticket #3',
        group:    ticket_group.name,
        priority: '2 normal',
        state:    'new',
        customer: customer.email,
        article:  {
          body: 'some test 123',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #3')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
    end

    it 'does ticket create with empty article body' do
      params = {
        title:    'a new ticket with empty article body',
        group:    ticket_group.name,
        priority: '2 normal',
        state:    'new',
        customer: customer.email,
        article:  { body: '' }
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket with empty article body')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
      ticket = Ticket.find(json_response['id'])
      expect(ticket.articles.count).to eq(1)
      article = ticket.articles.first
      expect(article.body).to eq('')
    end

    it 'does ticket create with agent - wrong owner_id - 0 (01.05)' do
      params = {
        title:       'a new ticket #4',
        group:       ticket_group.name,
        priority:    '2 normal',
        owner_id:    0,
        state:       'new',
        customer_id: customer.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Invalid value for param \'owner_id\': 0')
    end

    it 'does ticket create with agent - wrong owner_id - "" (01.06)' do
      params = {
        title:       'a new ticket #5',
        group:       ticket_group.name,
        priority:    '2 normal',
        owner_id:    '',
        state:       'new',
        customer_id: customer.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #5')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
    end

    it 'does ticket create with agent - wrong owner_id - 99999 (01.07)' do
      params = {
        title:       'a new ticket #6',
        group:       ticket_group.name,
        priority:    '2 normal',
        owner_id:    99_999,
        state:       'new',
        customer_id: customer.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Invalid value for param \'owner_id\': 99999')
    end

    it 'does ticket create with agent - wrong owner_id - nil (01.08)' do
      params = {
        title:       'a new ticket #7',
        group:       ticket_group.name,
        priority:    '2 normal',
        owner_id:    nil,
        state:       'new',
        customer_id: customer.id,
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #7')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
    end

    it 'does ticket create with agent - minimal article with guess customer (01.09)' do
      params = {
        title:       'a new ticket #9',
        group:       ticket_group.name,
        priority:    '2 normal',
        state:       'new',
        customer_id: 'guess:some_new_customer@example.com',
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #9')
      expect(json_response['customer_id']).to eq(User.lookup(email: 'some_new_customer@example.com').id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
    end

    it 'does ticket create with agent - minimal article with guess customer (01.10)' do
      params = {
        title:       'a new ticket #10',
        group:       ticket_group.name,
        customer_id: 'guess:some_new_customer@example.com',
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #10')
      expect(json_response['customer_id']).to eq(User.lookup(email: 'some_new_customer@example.com').id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
    end

    it 'does ticket create with agent - minimal article with customer hash (01.11)' do
      params = {
        title:    'a new ticket #11',
        group:    ticket_group.name,
        customer: {
          firstname: 'some firstname',
          lastname:  'some lastname',
          email:     'some_new_customer@example.com',
        },
        article:  {
          body: 'some test 123',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #11')
      expect(json_response['customer_id']).to eq(User.lookup(email: 'some_new_customer@example.com').id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
    end

    it 'does ticket create with agent - minimal article with customer hash with article.origin_by (01.11)' do
      params = {
        title:    'a new ticket #11.1',
        group:    ticket_group.name,
        customer: {
          firstname: 'some firstname',
          lastname:  'some lastname',
          email:     'some_new_customer@example.com',
        },
        article:  {
          body:      'some test 123',
          origin_by: 'some_new_customer@example.com',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #11.1')
      expect(json_response['customer_id']).to eq(User.lookup(email: 'some_new_customer@example.com').id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
      ticket = Ticket.find(json_response['id'])
      article = ticket.articles.first
      expect(article.updated_by_id).to eq(agent.id)
      expect(article.created_by_id).to eq(agent.id)
      expect(article.origin_by_id).to eq(User.lookup(email: 'some_new_customer@example.com').id)
      expect(article.sender.name).to eq('Customer')
      expect(article.type.name).to eq('note')
      expect(article.from).to eq('some firstname some lastname')
    end

    it 'does ticket create with agent - minimal article with customer hash with article.origin_by (01.11)' do
      params = {
        title:    'a new ticket #11.2',
        group:    ticket_group.name,
        customer: {
          firstname: 'some firstname',
          lastname:  'some lastname',
          email:     'some_new_customer@example.com',
        },
        article:  {
          sender:    'Customer',
          body:      'some test 123',
          origin_by: 'some_new_customer@example.com',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #11.2')
      expect(json_response['customer_id']).to eq(User.lookup(email: 'some_new_customer@example.com').id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
      ticket = Ticket.find(json_response['id'])
      article = ticket.articles.first
      expect(article.updated_by_id).to eq(agent.id)
      expect(article.created_by_id).to eq(agent.id)
      expect(article.origin_by_id).to eq(User.lookup(email: 'some_new_customer@example.com').id)
      expect(article.sender.name).to eq('Customer')
      expect(article.type.name).to eq('note')
      expect(article.from).to eq('some firstname some lastname')
    end

    it 'does ticket create with agent - minimal article with customer hash with article.origin_by (01.11)' do
      params = {
        title:    'a new ticket #11.3',
        group:    ticket_group.name,
        customer: {
          firstname: 'some firstname',
          lastname:  'some lastname',
          email:     'some_new_customer@example.com',
        },
        article:  {
          sender:    'Agent',
          from:      'somebody',
          body:      'some test 123',
          origin_by: 'some_new_customer@example.com',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #11.3')
      expect(json_response['customer_id']).to eq(User.lookup(email: 'some_new_customer@example.com').id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
      ticket = Ticket.find(json_response['id'])
      article = ticket.articles.first
      expect(article.updated_by_id).to eq(agent.id)
      expect(article.created_by_id).to eq(agent.id)
      expect(article.origin_by_id).to eq(User.lookup(email: 'some_new_customer@example.com').id)
      expect(article.sender.name).to eq('Customer')
      expect(article.type.name).to eq('note')
      expect(article.from).to eq('some firstname some lastname')
    end

    it 'does ticket create with agent - minimal article with customer hash with article.origin_by (01.11)' do
      params = {
        title:    'a new ticket #11.4',
        group:    ticket_group.name,
        customer: {
          firstname: 'some firstname',
          lastname:  'some lastname',
          email:     'some_new_customer@example.com',
        },
        article:  {
          sender:    'Customer',
          body:      'some test 123',
          origin_by: customer.login,
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #11.4')
      expect(json_response['customer_id']).to eq(User.lookup(email: 'some_new_customer@example.com').id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
      ticket = Ticket.find(json_response['id'])
      article = ticket.articles.first
      expect(article.updated_by_id).to eq(agent.id)
      expect(article.created_by_id).to eq(agent.id)
      expect(article.origin_by_id).to eq(customer.id)
      expect(article.sender.name).to eq('Customer')
      expect(article.type.name).to eq('note')
      expect(article.from).to eq('Tickets Customer1')
    end

    it 'does ticket create with agent - minimal article with missing body - with customer.id (01.12)' do
      params = {
        title:       'a new ticket #12',
        group:       ticket_group.name,
        customer_id: customer.id,
        article:     {
          subject: 'some test 123',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Need at least article: { body: "some text" }')
    end

    it 'does ticket create with agent - minimal article and attachment with customer (01.13)' do
      params = {
        title:       'a new ticket #13',
        group:       ticket_group.name,
        customer_id: customer.id,
        article:     {
          subject:     'some test 123',
          body:        'some test 123',
          attachments: [
            { 'filename'  => 'some_file.txt',
              'data'      => 'dGVzdCAxMjM=',
              'mime-type' => 'text/plain' },
          ],
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #13')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      ticket = Ticket.find(json_response['id'])
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.first.attachments.count).to eq(1)
      file = ticket.articles.first.attachments.first
      expect(file.content).to eq('test 123')
      expect(file.filename).to eq('some_file.txt')
      expect(file.preferences['Mime-Type']).to eq('text/plain')
      expect(file.preferences['Content-ID']).to be_falsey
    end

    it 'does ticket create with agent - minimal article and attachment with customer (01.14)' do
      params = {
        title:       'a new ticket #14',
        group:       ticket_group.name,
        customer_id: customer.id,
        article:     {
          subject:     'some test 123',
          body:        'some test 123',
          attachments: [
            {
              'filename'  => 'some_file1.txt',
              'data'      => 'dGVzdCAxMjM=',
              'mime-type' => 'text/plain',
            },
            {
              'filename'  => 'some_file2.txt',
              'data'      => 'w6TDtsO8w58=',
              'mime-type' => 'text/plain',
            },
          ],
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #14')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      ticket = Ticket.find(json_response['id'])
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.first.attachments.count).to eq(2)
      file = ticket.articles.first.attachments.first
      expect(file.content).to eq('test 123')
      expect(file.filename).to eq('some_file1.txt')
      expect(file.preferences['Mime-Type']).to eq('text/plain')
      expect(file.preferences['Content-ID']).to be_falsey
    end

    it 'does ticket create with agent - minimal article and simple invalid base64 attachment with customer (01.15)' do
      params = {
        title:       'a new ticket #15',
        group:       ticket_group.name,
        customer_id: customer.id,
        article:     {
          subject:     'some test 123',
          body:        'some test 123',
          attachments: [
            { 'filename'  => 'some_file.txt',
              'data'      => 'ABC_INVALID_BASE64',
              'mime-type' => 'text/plain' },
          ],
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Invalid base64 for attachment with index \'0\'')
    end

    it 'does ticket create with agent - minimal article and large invalid base64 attachment with customer (01.15a)' do
      params = {
        title:       'a new ticket #15a',
        group:       ticket_group.name,
        customer_id: customer.id,
        article:     {
          subject:     'some test 123',
          body:        'some test 123',
          attachments: [
            { 'filename'  => 'some_file.txt',
              'data'      => "LARGE_INVALID_BASE64_#{'#' * 20_000_000}",
              'mime-type' => 'text/plain' },
          ],
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Invalid base64 for attachment with index \'0\'')
    end

    it 'does ticket create with agent - minimal article and valid multiline base64 with linebreaks attachment with customer (01.15b)' do
      params = {
        title:       'a new ticket #15b',
        group:       ticket_group.name,
        customer_id: customer.id,
        article:     {
          subject:     'some test 123',
          body:        'some test 123',
          attachments: [
            { 'filename'  => 'some_file.txt',
              'data'      => Base64.encode64('a' * 1_000),
              'mime-type' => 'text/plain' },
          ],
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response['title']).to eq('a new ticket #15b')
      ticket = Ticket.find(json_response['id'])
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.first.attachments.count).to eq(1)
      file = ticket.articles.first.attachments.first
      expect(file.content).to eq('a' * 1_000)
    end

    it 'does ticket create with agent - minimal article and valid multiline base64 without linebreaks attachment with customer (01.15c)' do
      params = {
        title:       'a new ticket #15c',
        group:       ticket_group.name,
        customer_id: customer.id,
        article:     {
          subject:     'some test 123',
          body:        'some test 123',
          attachments: [
            { 'filename'  => 'some_file.txt',
              'data'      => Base64.strict_encode64('a' * 1_000),
              'mime-type' => 'text/plain' },
          ],
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response['title']).to eq('a new ticket #15c')
      ticket = Ticket.find(json_response['id'])
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.first.attachments.count).to eq(1)
      file = ticket.articles.first.attachments.first
      expect(file.content).to eq('a' * 1_000)
    end

    it 'does ticket create with agent - minimal article and attachment invalid base64 with customer (01.16)' do
      params = {
        title:       'a new ticket #16',
        group:       ticket_group.name,
        customer_id: customer.id,
        article:     {
          subject:     'some test 123',
          body:        'some test 123',
          attachments: [
            { 'filename' => 'some_file.txt',
              'data'     => 'dGVzdCAxMjM=' },
          ],
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Attachment needs \'mime-type\' param for attachment with index \'0\'')
    end

    it 'does ticket create with agent - minimal article and inline attachments with customer (01.17)' do
      params = {
        title:       'a new ticket #17',
        group:       ticket_group.name,
        customer_id: customer.id,
        article:     {
          content_type: 'text/html',
          subject:      'some test 123',
          body:         'some test 123 <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA
  AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
  9TXL0Y4OHwAAAABJRU5ErkJggg==" alt="Red dot" /> <img src="data:image/jpeg;base64,/9j/4QAYRXhpZgAASUkqAAgAAAAAAAAAAAAAAP/sABFEdWNreQABAAQAAAAJAAD/4QMtaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJBZG9iZSBYTVAgQ29yZSA1LjMtYzAxMSA2Ni4xNDU2NjEsIDIwMTIvMDIvMDYtMTQ6NTY6MjcgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCBDUzYgKE1hY2ludG9zaCkiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6QzJCOTE2NzlGQUEwMTFFNjg0M0NGQjU0OUU4MTFEOEIiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6QzJCOTE2N0FGQUEwMTFFNjg0M0NGQjU0OUU4MTFEOEIiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpDMkI5MTY3N0ZBQTAxMUU2ODQzQ0ZCNTQ5RTgxMUQ4QiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpDMkI5MTY3OEZBQTAxMUU2ODQzQ0ZCNTQ5RTgxMUQ4QiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pv/uAA5BZG9iZQBkwAAAAAH/2wCEABQRERoTGioZGSo1KCEoNTEpKCgpMUE4ODg4OEFEREREREREREREREREREREREREREREREREREREREREREREREQBFhoaIh0iKRoaKTkpIik5RDktLTlEREREOERERERERERERERERERERERERERERERERERERERERERERERERERERP/AABEIABAADAMBIgACEQEDEQH/xABbAAEBAAAAAAAAAAAAAAAAAAAEBQEBAQAAAAAAAAAAAAAAAAAABAUQAAEEAgMAAAAAAAAAAAAAAAABAhIDESIxBAURAAICAwAAAAAAAAAAAAAAAAESABNRoQP/2gAMAwEAAhEDEQA/AJDq1rfF3Imeg/1+lFy2oR564DKWWWbweV+Buf/Z">',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #17')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      ticket = Ticket.find(json_response['id'])
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.first.attachments.count).to eq(2)
      file = ticket.articles.first.attachments[0]
      expect(Digest::MD5.hexdigest(file.content)).to eq('d3c1e09bdefb92b6a06b791a24ca9599')
      expect(file.filename).to eq('image1.png')
      expect(file.preferences['Mime-Type']).to eq('image/png')
      expect(file.preferences['Content-ID']).to match(%r{#{ticket.id}\..+?@zammad.example.com})
      expect(file.preferences['Content-ID']).to be_truthy
      file = ticket.articles.first.attachments[1]
      expect(Digest::MD5.hexdigest(file.content)).to eq('006a2ca3793b550c8fe444acdeb39252')
      expect(file.filename).to eq('image2.jpeg')
      expect(file.preferences['Mime-Type']).to eq('image/jpeg')
      expect(file.preferences['Content-ID']).to match(%r{#{ticket.id}\..+?@zammad.example.com})
      expect(file.preferences['Content-ID']).to be_truthy
    end

    it 'does ticket create with agent - minimal article and inline attachments with customer (01.18)' do
      params = {
        title:       'a new ticket #18',
        group:       ticket_group.name,
        customer_id: customer.id,
        article:     {
          content_type: 'text/html',
          subject:      'some test 123',
          body:         'some test 123 <img src="data:image/jpeg;base64,/9j/4QAYRXhpZgAASUkqAAgAAAAAAAAAAAAAAP/sABFEdWNreQABAAQAAAAJAAD/4QMtaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJBZG9iZSBYTVAgQ29yZSA1LjMtYzAxMSA2Ni4xNDU2NjEsIDIwMTIvMDIvMDYtMTQ6NTY6MjcgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCBDUzYgKE1hY2ludG9zaCkiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6QzJCOTE2NzlGQUEwMTFFNjg0M0NGQjU0OUU4MTFEOEIiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6QzJCOTE2N0FGQUEwMTFFNjg0M0NGQjU0OUU4MTFEOEIiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpDMkI5MTY3N0ZBQTAxMUU2ODQzQ0ZCNTQ5RTgxMUQ4QiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpDMkI5MTY3OEZBQTAxMUU2ODQzQ0ZCNTQ5RTgxMUQ4QiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pv/uAA5BZG9iZQBkwAAAAAH/2wCEABQRERoTGioZGSo1KCEoNTEpKCgpMUE4ODg4OEFEREREREREREREREREREREREREREREREREREREREREREREREQBFhoaIh0iKRoaKTkpIik5RDktLTlEREREOERERERERERERERERERERERERERERERERERERERERERERERERERERP/AABEIABAADAMBIgACEQEDEQH/xABbAAEBAAAAAAAAAAAAAAAAAAAEBQEBAQAAAAAAAAAAAAAAAAAABAUQAAEEAgMAAAAAAAAAAAAAAAABAhIDESIxBAURAAICAwAAAAAAAAAAAAAAAAESABNRoQP/2gAMAwEAAhEDEQA/AJDq1rfF3Imeg/1+lFy2oR564DKWWWbweV+Buf/Z"
  >',
          attachments:  [
            { 'filename'  => 'some_file.txt',
              'data'      => 'dGVzdCAxMjM=',
              'mime-type' => 'text/plain' },
          ],
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #18')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      ticket = Ticket.find(json_response['id'])
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.first.attachments.count).to eq(2)
      file = ticket.articles.first.attachments[0]
      expect(Digest::MD5.hexdigest(file.content)).to eq('006a2ca3793b550c8fe444acdeb39252')
      expect(file.filename).to eq('image1.jpeg')
      expect(file.preferences['Mime-Type']).to eq('image/jpeg')
      expect(file.preferences['Content-ID']).to be_truthy
      expect(file.preferences['Content-ID']).to match(%r{#{ticket.id}\..+?@zammad.example.com})
      file = ticket.articles.first.attachments[1]
      expect(Digest::MD5.hexdigest(file.content)).to eq('39d0d586a701e199389d954f2d592720')
      expect(file.filename).to eq('some_file.txt')
      expect(file.preferences['Mime-Type']).to eq('text/plain')
      expect(file.preferences['Content-ID']).to be_falsey
    end

    it 'does ticket create with agent (02.02)' do
      params = {
        title:    'a new ticket #1',
        state:    'new',
        priority: '2 normal',
        group:    ticket_group.name,
        customer: 'tickets-customer1@example.com',
        article:  {
          content_type: 'text/plain', # or text/html
          body:         'some body',
        },
        links:    {
          Ticket: {
            parent: [1],
          }
        }
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #1')
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
      links = Link.list(
        link_object:       'Ticket',
        link_object_value: json_response['id'],
      )
      expect(links[0]['link_type']).to eq('child')
      expect(links[0]['link_object']).to eq('Ticket')
      expect(links[0]['link_object_value']).to eq(1)
    end

    it 'does ticket with wrong ticket id (02.03)' do
      group = create(:group)
      ticket = create(
        :ticket,
        title:       'ticket with wrong ticket id',
        group_id:    group.id,
        customer_id: customer.id,
      )
      authenticated_as(agent)
      get "/api/v1/tickets/#{ticket.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized')

      params = {
        title: 'ticket with wrong ticket id - 2',
      }
      put "/api/v1/tickets/#{ticket.id}", params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized')

      delete "/api/v1/tickets/#{ticket.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized')
    end

    it 'does ticket with correct ticket id (02.04)' do
      title = "ticket with corret ticket id testagent#{rand(999_999_999)}"
      ticket = create(
        :ticket,
        title:       title,
        group:       ticket_group,
        customer_id: customer.id,
        preferences: {
          some_key1: 123,
        },
      )
      authenticated_as(agent)
      get "/api/v1/tickets/#{ticket.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(ticket.id)
      expect(json_response['title']).to eq(title)
      expect(json_response['customer_id']).to eq(ticket.customer_id)
      expect(json_response['updated_by_id']).to eq(1)
      expect(json_response['created_by_id']).to eq(1)
      expect(json_response['preferences']['some_key1']).to eq(123)

      params = {
        title:       "#{title} - 2",
        customer_id: agent.id,
        preferences: {
          some_key2: 'abc',
        },
      }
      put "/api/v1/tickets/#{ticket.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(ticket.id)
      expect(json_response['title']).to eq("#{title} - 2")
      expect(json_response['customer_id']).to eq(agent.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(1)
      expect(json_response['preferences']['some_key1']).to eq(123)
      expect(json_response['preferences']['some_key2']).to eq('abc')

      params = {
        ticket_id: ticket.id,
        subject:   'some subject',
        body:      'some body',
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      article_json_response = json_response
      expect(article_json_response).to be_a_kind_of(Hash)
      expect(article_json_response['ticket_id']).to eq(ticket.id)
      expect(article_json_response['from']).to eq('Tickets Agent')
      expect(article_json_response['subject']).to eq('some subject')
      expect(article_json_response['body']).to eq('some body')
      expect(article_json_response['content_type']).to eq('text/plain')
      expect(article_json_response['internal']).to eq(false)
      expect(article_json_response['created_by_id']).to eq(agent.id)
      expect(article_json_response['sender_id']).to eq(Ticket::Article::Sender.lookup(name: 'Agent').id)
      expect(article_json_response['type_id']).to eq(Ticket::Article::Type.lookup(name: 'note').id)

      Scheduler.worker(true)
      get "/api/v1/tickets/search?query=#{CGI.escape(title)}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets'][0]).to eq(ticket.id)
      expect(json_response['tickets_count']).to eq(1)

      params = {
        condition: {
          'ticket.title' => {
            operator: 'contains',
            value:    title,
          },
        },
      }
      post '/api/v1/tickets/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets'][0]).to eq(ticket.id)
      expect(json_response['tickets_count']).to eq(1)

      delete "/api/v1/ticket_articles/#{article_json_response['id']}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      params = {
        from:      'something which should not be changed on server side',
        ticket_id: ticket.id,
        subject:   'some subject',
        body:      'some body',
        type:      'email',
        internal:  true,
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['ticket_id']).to eq(ticket.id)
      expect(json_response['from']).to eq(%("Tickets Agent via #{ticket_group.email_address.realname}" <#{ticket_group.email_address.email}>))
      expect(json_response['subject']).to eq('some subject')
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['internal']).to eq(true)
      expect(json_response['created_by_id']).to eq(agent.id)
      expect(json_response['sender_id']).to eq(Ticket::Article::Sender.lookup(name: 'Agent').id)
      expect(json_response['type_id']).to eq(Ticket::Article::Type.lookup(name: 'email').id)

      params = {
        subject: 'new subject',
      }
      put "/api/v1/ticket_articles/#{json_response['id']}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['ticket_id']).to eq(ticket.id)
      expect(json_response['from']).to eq(%("Tickets Agent via #{ticket_group.email_address.realname}" <#{ticket_group.email_address.email}>))
      expect(json_response['subject']).not_to eq('new subject')
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['internal']).to eq(true)
      expect(json_response['created_by_id']).to eq(agent.id)
      expect(json_response['sender_id']).to eq(Ticket::Article::Sender.lookup(name: 'Agent').id)
      expect(json_response['type_id']).to eq(Ticket::Article::Type.lookup(name: 'email').id)

      params = {
        from:      'something which should not be changed on server side',
        ticket_id: ticket.id,
        subject:   'some subject',
        body:      'some body',
        type:      'email',
        internal:  false,
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response['internal']).to eq(false)

      delete "/api/v1/ticket_articles/#{json_response['id']}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized (communication articles cannot be deleted)!')

      delete "/api/v1/tickets/#{ticket.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized (admin permission required)!')
    end

    it 'does ticket with correct ticket id (02.05)' do
      ticket = create(
        :ticket,
        title:       'ticket with corret ticket id',
        group:       ticket_group,
        customer_id: customer.id,
      )
      authenticated_as(admin)
      get "/api/v1/tickets/#{ticket.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(ticket.id)
      expect(json_response['title']).to eq('ticket with corret ticket id')
      expect(json_response['customer_id']).to eq(ticket.customer_id)
      expect(json_response['updated_by_id']).to eq(1)
      expect(json_response['created_by_id']).to eq(1)

      params = {
        title:       'ticket with corret ticket id - 2',
        customer_id: agent.id,
      }
      put "/api/v1/tickets/#{ticket.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(ticket.id)
      expect(json_response['title']).to eq('ticket with corret ticket id - 2')
      expect(json_response['customer_id']).to eq(agent.id)
      expect(json_response['updated_by_id']).to eq(admin.id)
      expect(json_response['created_by_id']).to eq(1)

      params = {
        from:      'something which should not be changed on server side',
        ticket_id: ticket.id,
        subject:   'some subject',
        body:      'some body',
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['ticket_id']).to eq(ticket.id)
      expect(json_response['from']).to eq('Tickets Admin')
      expect(json_response['subject']).to eq('some subject')
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['internal']).to eq(false)
      expect(json_response['created_by_id']).to eq(admin.id)
      expect(json_response['sender_id']).to eq(Ticket::Article::Sender.lookup(name: 'Agent').id)
      expect(json_response['type_id']).to eq(Ticket::Article::Type.lookup(name: 'note').id)

      params = {
        subject:  'new subject',
        internal: true,
      }
      put "/api/v1/ticket_articles/#{json_response['id']}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['ticket_id']).to eq(ticket.id)
      expect(json_response['from']).to eq('Tickets Admin')
      expect(json_response['subject']).not_to eq('new subject')
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['internal']).to eq(true)
      expect(json_response['created_by_id']).to eq(admin.id)
      expect(json_response['sender_id']).to eq(Ticket::Article::Sender.lookup(name: 'Agent').id)
      expect(json_response['type_id']).to eq(Ticket::Article::Type.lookup(name: 'note').id)

      delete "/api/v1/ticket_articles/#{json_response['id']}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      params = {
        ticket_id: ticket.id,
        subject:   'some subject',
        body:      'some body',
        type:      'email',
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['ticket_id']).to eq(ticket.id)
      expect(json_response['from']).to eq(%("Tickets Admin via #{ticket_group.email_address.realname}" <#{ticket_group.email_address.email}>))
      expect(json_response['subject']).to eq('some subject')
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['internal']).to eq(false)
      expect(json_response['created_by_id']).to eq(admin.id)
      expect(json_response['sender_id']).to eq(Ticket::Article::Sender.lookup(name: 'Agent').id)
      expect(json_response['type_id']).to eq(Ticket::Article::Type.lookup(name: 'email').id)

      delete "/api/v1/ticket_articles/#{json_response['id']}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)

      delete "/api/v1/tickets/#{ticket.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
    end

    it 'does ticket pagination (02.05)' do
      title = "ticket pagination #{rand(999_999_999)}"
      tickets = []
      (1..20).each do |count|
        ticket = create(
          :ticket,
          title:       "#{title} - #{count}",
          group:       ticket_group,
          customer_id: customer.id,
        )
        create(
          :ticket_article,
          type:      Ticket::Article::Type.lookup(name: 'note'),
          sender:    Ticket::Article::Sender.lookup(name: 'Customer'),
          ticket_id: ticket.id,
        )
        tickets.push ticket
        travel 2.seconds
      end

      authenticated_as(admin)
      get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets'][0]).to eq(tickets[19].id)
      expect(json_response['tickets'][19]).to eq(tickets[0].id)
      expect(json_response['tickets_count']).to eq(20)

      get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=10", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets'][0]).to eq(tickets[19].id)
      expect(json_response['tickets'][9]).to eq(tickets[10].id)
      expect(json_response['tickets_count']).to eq(10)

      get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40&page=1&per_page=5", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets'][0]).to eq(tickets[19].id)
      expect(json_response['tickets'][4]).to eq(tickets[15].id)
      expect(json_response['tickets_count']).to eq(5)

      get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40&page=2&per_page=5", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets'][0]).to eq(tickets[14].id)
      expect(json_response['tickets'][4]).to eq(tickets[10].id)
      expect(json_response['tickets_count']).to eq(5)

      get '/api/v1/tickets?limit=40&page=1&per_page=5', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      tickets = Ticket.order(:id).limit(5)
      expect(json_response[0]['id']).to eq(tickets[0].id)
      expect(json_response[4]['id']).to eq(tickets[4].id)
      expect(json_response.count).to eq(5)

      get '/api/v1/tickets?limit=40&page=2&per_page=5', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      tickets = Ticket.order(:id).limit(10)
      expect(json_response[0]['id']).to eq(tickets[5].id)
      expect(json_response[4]['id']).to eq(tickets[9].id)
      expect(json_response.count).to eq(5)

    end

    it 'does ticket create with customer minimal (03.01)' do
      params = {
        title:    'a new ticket #c1',
        state:    'new',
        priority: '2 normal',
        group:    ticket_group.name,
        article:  {
          body: 'some body',
        },
      }
      authenticated_as(customer)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #c1')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(customer.id)
      expect(json_response['created_by_id']).to eq(customer.id)
    end

    it 'does ticket create with customer with wrong customer (03.02)' do
      params = {
        title:       'a new ticket #c2',
        state:       'new',
        priority:    '2 normal',
        group:       ticket_group.name,
        customer_id: agent.id,
        article:     {
          content_type: 'text/plain', # or text/html
          body:         'some body',
          sender:       'System',
        },
      }
      authenticated_as(customer)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #c2')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(customer.id)
      expect(json_response['created_by_id']).to eq(customer.id)
    end

    it 'does ticket create with customer with wrong customer hash (03.03)' do
      params = {
        title:    'a new ticket #c2',
        state:    'new',
        priority: '2 normal',
        group:    ticket_group.name,
        customer: {
          firstname: agent.firstname,
          lastname:  agent.lastname,
          email:     agent.email,
        },
        article:  {
          content_type: 'text/plain', # or text/html
          body:         'some body',
          sender:       'System',
        },
      }
      authenticated_as(customer)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #c2')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(customer.id)
      expect(json_response['created_by_id']).to eq(customer.id)
    end

    it 'does ticket with wrong ticket id (03.04)' do
      ticket = create(
        :ticket,
        title:       'ticket with wrong ticket id',
        group:       ticket_group,
        customer_id: agent.id,
      )
      authenticated_as(customer)
      get "/api/v1/tickets/#{ticket.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized')

      params = {
        title: 'ticket with wrong ticket id - 2',
      }
      put "/api/v1/tickets/#{ticket.id}", params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized')

      delete "/api/v1/tickets/#{ticket.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized')
    end

    it 'does ticket with correct ticket id (03.05)' do
      title = "ticket with corret ticket id testme#{rand(999_999_999)}"
      ticket = create(
        :ticket,
        title:       title,
        group:       ticket_group,
        customer_id: customer.id,
      )
      authenticated_as(customer)
      get "/api/v1/tickets/#{ticket.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(ticket.id)
      expect(json_response['title']).to eq(title)
      expect(json_response['customer_id']).to eq(ticket.customer_id)
      expect(json_response['updated_by_id']).to eq(1)
      expect(json_response['created_by_id']).to eq(1)

      params = {
        title:       "#{title} - 2",
        customer_id: agent.id,
      }
      put "/api/v1/tickets/#{ticket.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(ticket.id)
      expect(json_response['title']).to eq("#{title} - 2")
      expect(json_response['customer_id']).to eq(ticket.customer_id)
      expect(json_response['updated_by_id']).to eq(customer.id)
      expect(json_response['created_by_id']).to eq(1)

      params = {
        ticket_id: ticket.id,
        subject:   'some subject',
        body:      'some body',
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      article_json_response = json_response
      expect(article_json_response).to be_a_kind_of(Hash)
      expect(article_json_response['ticket_id']).to eq(ticket.id)
      expect(article_json_response['from']).to eq('Tickets Customer1')
      expect(article_json_response['subject']).to eq('some subject')
      expect(article_json_response['body']).to eq('some body')
      expect(article_json_response['content_type']).to eq('text/plain')
      expect(article_json_response['created_by_id']).to eq(customer.id)
      expect(article_json_response['sender_id']).to eq(Ticket::Article::Sender.lookup(name: 'Customer').id)
      expect(article_json_response['type_id']).to eq(Ticket::Article::Type.lookup(name: 'note').id)

      Scheduler.worker(true)
      get "/api/v1/tickets/search?query=#{CGI.escape(title)}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets'][0]).to eq(ticket.id)
      expect(json_response['tickets_count']).to eq(1)

      params = {
        condition: {
          'ticket.title' => {
            operator: 'contains',
            value:    title,
          },
        },
      }
      post '/api/v1/tickets/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets'][0]).to eq(ticket.id)
      expect(json_response['tickets_count']).to eq(1)

      delete "/api/v1/ticket_articles/#{article_json_response['id']}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized (agent permission required)!')

      params = {
        ticket_id: ticket.id,
        subject:   'some subject',
        body:      'some body',
        type:      'email',
        sender:    'Agent',
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['ticket_id']).to eq(ticket.id)
      expect(json_response['from']).to eq('Tickets Customer1')
      expect(json_response['subject']).to eq('some subject')
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['created_by_id']).to eq(customer.id)
      expect(json_response['sender_id']).to eq(Ticket::Article::Sender.lookup(name: 'Customer').id)
      expect(json_response['type_id']).to eq(Ticket::Article::Type.lookup(name: 'note').id)

      delete "/api/v1/ticket_articles/#{json_response['id']}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized (agent permission required)!')

      params = {
        from:      'something which should not be changed on server side',
        ticket_id: ticket.id,
        subject:   'some subject',
        body:      'some body',
        type:      'web',
        sender:    'Agent',
        internal:  true,
      }

      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['ticket_id']).to eq(ticket.id)
      expect(json_response['from']).to eq('Tickets Customer1 <tickets-customer1@example.com>')
      expect(json_response['subject']).to eq('some subject')
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['internal']).to eq(false)
      expect(json_response['created_by_id']).to eq(customer.id)
      expect(json_response['sender_id']).to eq(Ticket::Article::Sender.lookup(name: 'Customer').id)
      expect(json_response['type_id']).to eq(Ticket::Article::Type.lookup(name: 'web').id)

      params = {
        subject: 'new subject',
      }
      put "/api/v1/ticket_articles/#{json_response['id']}", params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized (ticket.agent or admin permission required)!')

      delete "/api/v1/tickets/#{ticket.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized (admin permission required)!')
    end

    it 'does ticket create with agent - minimal article with customer hash with article.origin_by (03.6)' do
      authenticated_as(customer)
      params = {
        title:    'a new ticket #3.6',
        group:    ticket_group.name,
        customer: {
          firstname: 'some firstname',
          lastname:  'some lastname',
          email:     'some_new_customer@example.com',
        },
        article:  {
          body:      'some test 123',
          origin_by: agent.login,
        },
      }

      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #3.6')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(customer.id)
      expect(json_response['created_by_id']).to eq(customer.id)
      ticket = Ticket.find(json_response['id'])
      article = ticket.articles.first
      expect(article.updated_by_id).to eq(customer.id)
      expect(article.created_by_id).to eq(customer.id)
      expect(article.origin_by_id).to eq(customer.id)
      expect(article.sender.name).to eq('Customer')
      expect(article.type.name).to eq('note')
      expect(article.from).to eq('Tickets Customer1')
    end

    it 'does ticket create with agent - minimal article with customer hash with article.origin_by (03.6)' do
      authenticated_as(customer)
      params = {
        title:    'a new ticket #3.6.1',
        group:    ticket_group.name,
        customer: {
          firstname: 'some firstname',
          lastname:  'some lastname',
          email:     'some_new_customer@example.com',
        },
        article:  {
          sender:       'Agent',
          body:         'some test 123',
          origin_by_id: agent.id,
        },
      }

      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq('a new ticket #3.6.1')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(customer.id)
      expect(json_response['created_by_id']).to eq(customer.id)
      ticket = Ticket.find(json_response['id'])
      article = ticket.articles.first
      expect(article.updated_by_id).to eq(customer.id)
      expect(article.created_by_id).to eq(customer.id)
      expect(article.origin_by_id).to eq(customer.id)
      expect(article.sender.name).to eq('Customer')
      expect(article.type.name).to eq('note')
      expect(article.from).to eq('Tickets Customer1')
    end

    it 'does ticket show and response format (04.01)' do
      title = "ticket testagent#{rand(999_999_999)}"
      ticket = create(
        :ticket,
        title:         title,
        group:         ticket_group,
        customer_id:   customer.id,
        updated_by_id: agent.id,
        created_by_id: agent.id,
      )
      authenticated_as(agent)
      get "/api/v1/tickets/#{ticket.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(ticket.id)
      expect(json_response['title']).to eq(ticket.title)
      expect(json_response['group']).to be_falsey
      expect(json_response['priority']).to be_falsey
      expect(json_response['owner']).to be_falsey
      expect(json_response['customer_id']).to eq(ticket.customer_id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      get "/api/v1/tickets/#{ticket.id}?expand=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(ticket.id)
      expect(json_response['title']).to eq(ticket.title)
      expect(json_response['customer_id']).to eq(ticket.customer_id)
      expect(json_response['group']).to eq(ticket.group.name)
      expect(json_response['priority']).to eq(ticket.priority.name)
      expect(json_response['owner']).to eq(ticket.owner.login)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      get "/api/v1/tickets/#{ticket.id}?expand=false", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(ticket.id)
      expect(json_response['title']).to eq(ticket.title)
      expect(json_response['group']).to be_falsey
      expect(json_response['priority']).to be_falsey
      expect(json_response['owner']).to be_falsey
      expect(json_response['customer_id']).to eq(ticket.customer_id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      get "/api/v1/tickets/#{ticket.id}?full=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(ticket.id)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Ticket']).to be_truthy
      expect(json_response['assets']['Ticket'][ticket.id.to_s]).to be_truthy
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['id']).to eq(ticket.id)
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['title']).to eq(ticket.title)
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['customer_id']).to eq(ticket.customer_id)

      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][agent.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][agent.id.to_s]['id']).to eq(agent.id)
      expect(json_response['assets']['User'][agent.id.to_s]['firstname']).to eq(agent.firstname)
      expect(json_response['assets']['User'][agent.id.to_s]['lastname']).to eq(agent.lastname)

      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][customer.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][customer.id.to_s]['id']).to eq(customer.id)
      expect(json_response['assets']['User'][customer.id.to_s]['firstname']).to eq(customer.firstname)
      expect(json_response['assets']['User'][customer.id.to_s]['lastname']).to eq(customer.lastname)

      get "/api/v1/tickets/#{ticket.id}?full=false", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(ticket.id)
      expect(json_response['title']).to eq(ticket.title)
      expect(json_response['group']).to be_falsey
      expect(json_response['priority']).to be_falsey
      expect(json_response['owner']).to be_falsey
      expect(json_response['customer_id']).to eq(ticket.customer_id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
    end

    it 'does ticket index and response format (04.02)' do
      title = "ticket testagent#{rand(999_999_999)}"
      ticket = create(
        :ticket,
        title:         title,
        group:         ticket_group,
        customer_id:   customer.id,
        updated_by_id: agent.id,
        created_by_id: agent.id,
      )
      authenticated_as(agent)
      get '/api/v1/tickets', params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]).to be_a_kind_of(Hash)
      expect(json_response[0]['id']).to eq(1)
      expect(json_response[1]['id']).to eq(ticket.id)
      expect(json_response[1]['title']).to eq(ticket.title)
      expect(json_response[1]['group']).to be_falsey
      expect(json_response[1]['priority']).to be_falsey
      expect(json_response[1]['owner']).to be_falsey
      expect(json_response[1]['customer_id']).to eq(ticket.customer_id)
      expect(json_response[1]['updated_by_id']).to eq(agent.id)
      expect(json_response[1]['created_by_id']).to eq(agent.id)

      get '/api/v1/tickets?expand=true', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]).to be_a_kind_of(Hash)
      expect(json_response[0]['id']).to eq(1)
      expect(json_response[1]['id']).to eq(ticket.id)
      expect(json_response[1]['title']).to eq(ticket.title)
      expect(json_response[1]['customer_id']).to eq(ticket.customer_id)
      expect(json_response[1]['group']).to eq(ticket.group.name)
      expect(json_response[1]['priority']).to eq(ticket.priority.name)
      expect(json_response[1]['owner']).to eq(ticket.owner.login)
      expect(json_response[1]['updated_by_id']).to eq(agent.id)
      expect(json_response[1]['created_by_id']).to eq(agent.id)

      get '/api/v1/tickets?expand=false', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]).to be_a_kind_of(Hash)
      expect(json_response[0]['id']).to eq(1)
      expect(json_response[1]['id']).to eq(ticket.id)
      expect(json_response[1]['title']).to eq(ticket.title)
      expect(json_response[1]['group']).to be_falsey
      expect(json_response[1]['priority']).to be_falsey
      expect(json_response[1]['owner']).to be_falsey
      expect(json_response[1]['customer_id']).to eq(ticket.customer_id)
      expect(json_response[1]['updated_by_id']).to eq(agent.id)
      expect(json_response[1]['created_by_id']).to eq(agent.id)

      get '/api/v1/tickets?full=true', params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['record_ids'].class).to eq(Array)
      expect(json_response['record_ids'][0]).to eq(1)
      expect(json_response['record_ids'][1]).to eq(ticket.id)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Ticket']).to be_truthy
      expect(json_response['assets']['Ticket'][ticket.id.to_s]).to be_truthy
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['id']).to eq(ticket.id)
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['title']).to eq(ticket.title)
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['customer_id']).to eq(ticket.customer_id)

      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][agent.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][agent.id.to_s]['id']).to eq(agent.id)
      expect(json_response['assets']['User'][agent.id.to_s]['firstname']).to eq(agent.firstname)
      expect(json_response['assets']['User'][agent.id.to_s]['lastname']).to eq(agent.lastname)

      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][customer.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][customer.id.to_s]['id']).to eq(customer.id)
      expect(json_response['assets']['User'][customer.id.to_s]['firstname']).to eq(customer.firstname)
      expect(json_response['assets']['User'][customer.id.to_s]['lastname']).to eq(customer.lastname)

      get '/api/v1/tickets?full=false', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]).to be_a_kind_of(Hash)
      expect(json_response[0]['id']).to eq(1)
      expect(json_response[1]['id']).to eq(ticket.id)
      expect(json_response[1]['title']).to eq(ticket.title)
      expect(json_response[1]['group']).to be_falsey
      expect(json_response[1]['priority']).to be_falsey
      expect(json_response[1]['owner']).to be_falsey
      expect(json_response[1]['customer_id']).to eq(ticket.customer_id)
      expect(json_response[1]['updated_by_id']).to eq(agent.id)
      expect(json_response[1]['created_by_id']).to eq(agent.id)
    end

    it 'does ticket create and response format (04.03)' do
      title = "ticket testagent#{rand(999_999_999)}"
      params = {
        title:       title,
        group:       ticket_group.name,
        customer_id: customer.id,
        state:       'new',
        priority:    '2 normal',
        article:     {
          body: 'some test 123',
        },
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)

      ticket = Ticket.find(json_response['id'])
      expect(json_response['state_id']).to eq(ticket.state_id)
      expect(json_response['state']).to be_falsey
      expect(json_response['priority_id']).to eq(ticket.priority_id)
      expect(json_response['priority']).to be_falsey
      expect(json_response['group_id']).to eq(ticket.group_id)
      expect(json_response['group']).to be_falsey
      expect(json_response['title']).to eq(title)
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      post '/api/v1/tickets?expand=true', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)

      ticket = Ticket.find(json_response['id'])
      expect(json_response['state_id']).to eq(ticket.state_id)
      expect(json_response['state']).to eq(ticket.state.name)
      expect(json_response['priority_id']).to eq(ticket.priority_id)
      expect(json_response['priority']).to eq(ticket.priority.name)
      expect(json_response['group_id']).to eq(ticket.group_id)
      expect(json_response['group']).to eq(ticket.group.name)
      expect(json_response['title']).to eq(title)
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      post '/api/v1/tickets?full=true', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)

      ticket = Ticket.find(json_response['id'])
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Ticket']).to be_truthy
      expect(json_response['assets']['Ticket'][ticket.id.to_s]).to be_truthy
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['id']).to eq(ticket.id)
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['title']).to eq(title)
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['customer_id']).to eq(ticket.customer_id)

      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][agent.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][agent.id.to_s]['id']).to eq(agent.id)
      expect(json_response['assets']['User'][agent.id.to_s]['firstname']).to eq(agent.firstname)
      expect(json_response['assets']['User'][agent.id.to_s]['lastname']).to eq(agent.lastname)

      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][customer.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][customer.id.to_s]['id']).to eq(customer.id)
      expect(json_response['assets']['User'][customer.id.to_s]['firstname']).to eq(customer.firstname)
      expect(json_response['assets']['User'][customer.id.to_s]['lastname']).to eq(customer.lastname)

    end

    it 'does ticket update and response formats (04.04)' do
      title = "ticket testagent#{rand(999_999_999)}"
      ticket = create(
        :ticket,
        title:         title,
        group:         ticket_group,
        customer_id:   customer.id,
        updated_by_id: agent.id,
        created_by_id: agent.id,
      )

      params = {
        title: 'a update ticket #1',
      }
      authenticated_as(agent)
      put "/api/v1/tickets/#{ticket.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      ticket = Ticket.find(json_response['id'])
      expect(json_response['state_id']).to eq(ticket.state_id)
      expect(json_response['state']).to be_falsey
      expect(json_response['priority_id']).to eq(ticket.priority_id)
      expect(json_response['priority']).to be_falsey
      expect(json_response['group_id']).to eq(ticket.group_id)
      expect(json_response['group']).to be_falsey
      expect(json_response['title']).to eq('a update ticket #1')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      params = {
        title: 'a update ticket #2',
      }
      put "/api/v1/tickets/#{ticket.id}?expand=true", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      ticket = Ticket.find(json_response['id'])
      expect(json_response['state_id']).to eq(ticket.state_id)
      expect(json_response['state']).to eq(ticket.state.name)
      expect(json_response['priority_id']).to eq(ticket.priority_id)
      expect(json_response['priority']).to eq(ticket.priority.name)
      expect(json_response['group_id']).to eq(ticket.group_id)
      expect(json_response['group']).to eq(ticket.group.name)
      expect(json_response['title']).to eq('a update ticket #2')
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      params = {
        title: 'a update ticket #3',
      }
      put "/api/v1/tickets/#{ticket.id}?full=true", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      ticket = Ticket.find(json_response['id'])
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Ticket']).to be_truthy
      expect(json_response['assets']['Ticket'][ticket.id.to_s]).to be_truthy
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['id']).to eq(ticket.id)
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['title']).to eq('a update ticket #3')
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['customer_id']).to eq(ticket.customer_id)

      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][agent.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][agent.id.to_s]['id']).to eq(agent.id)
      expect(json_response['assets']['User'][agent.id.to_s]['firstname']).to eq(agent.firstname)
      expect(json_response['assets']['User'][agent.id.to_s]['lastname']).to eq(agent.lastname)

      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][customer.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][customer.id.to_s]['id']).to eq(customer.id)
      expect(json_response['assets']['User'][customer.id.to_s]['firstname']).to eq(customer.firstname)
      expect(json_response['assets']['User'][customer.id.to_s]['lastname']).to eq(customer.lastname)

      # it should be not possible to modify the ticket number
      expected_ticket_number = ticket.number
      params = {
        title:  'a update ticket #4',
        number: '77777',
      }
      put "/api/v1/tickets/#{ticket.id}?full=true", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      ticket = Ticket.find(json_response['id'])
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['title']).to eq('a update ticket #4')
      expect(json_response['assets']['Ticket'][ticket.id.to_s]['number']).to eq(expected_ticket_number)
    end

    it 'does ticket update with empty article param' do
      title = 'a new ticket'
      ticket = create(
        :ticket,
        title:         title,
        group:         ticket_group,
        customer_id:   customer.id,
        updated_by_id: agent.id,
        created_by_id: agent.id,
      )

      params = {
        state:   Ticket::State.lookup(name: 'close'),
        article: {}
      }
      authenticated_as(agent)
      put "/api/v1/tickets/#{ticket.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['state_id']).to eq(ticket.state_id)
      expect(json_response['state']).to be_falsey
      expect(json_response['priority_id']).to eq(ticket.priority_id)
      expect(json_response['priority']).to be_falsey
      expect(json_response['group_id']).to eq(ticket.group_id)
      expect(json_response['group']).to be_falsey
      expect(json_response['customer_id']).to eq(customer.id)
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
      expect(json_response['state_id']).to eq(Ticket::State.lookup(name: 'new').id)
      expect(json_response['title']).to eq(ticket.title)
      expect(ticket.articles.count).to eq(0)
    end

    it 'does ticket split with html - check attachments (05.01)' do
      ticket = create(
        :ticket,
        title:         'some title',
        group:         ticket_group,
        customer_id:   customer.id,
        updated_by_id: agent.id,
        created_by_id: agent.id,
      )
      article = create(
        :ticket_article,
        type:         Ticket::Article::Type.lookup(name: 'note'),
        sender:       Ticket::Article::Sender.lookup(name: 'Customer'),
        body:         '<b>test</b> <img src="cid:15.274327094.140938@ZAMMAD.example.com"/> test <img src="cid:15.274327094.140938.3@ZAMMAD.example.com"/>',
        content_type: 'text/html',
        ticket_id:    ticket.id,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file1_normally_should_be_an_image',
        filename:      'some_file1.jpg',
        preferences:   {
          'Content-Type'        => 'image/jpeg',
          'Mime-Type'           => 'image/jpeg',
          'Content-ID'          => '15.274327094.140938@zammad.example.com',
          'Content-Disposition' => 'inline',
        },
        created_by_id: 1,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file2_normally_should_be_an_image',
        filename:      'some_file2.jpg',
        preferences:   {
          'Content-Type'        => 'image/jpeg',
          'Mime-Type'           => 'image/jpeg',
          'Content-ID'          => '15.274327094.140938.2@zammad.example.com',
          'Content-Disposition' => 'inline',
        },
        created_by_id: 1,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file3_normally_should_be_an_image',
        filename:      'some_file3.jpg',
        preferences:   {
          'Content-Type' => 'image/jpeg',
          'Mime-Type'    => 'image/jpeg',
          'Content-ID'   => '15.274327094.140938.3@zammad.example.com',
        },
        created_by_id: 1,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file4_normally_should_be_an_image',
        filename:      'some_file4.jpg',
        preferences:   {
          'Content-Type' => 'image/jpeg',
          'Mime-Type'    => 'image/jpeg',
          'Content-ID'   => '15.274327094.140938.4@zammad.example.com',
        },
        created_by_id: 1,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file1_normally_should_be_an_pdf',
        filename:      'Rechnung_RE-2018-200.pdf',
        preferences:   {
          'Content-Type'        => 'application/octet-stream; name="Rechnung_RE-2018-200.pdf"',
          'Mime-Type'           => 'application/octet-stream',
          'Content-ID'          => '8AB0BEC88984EE4EBEF643C79C8E0346@zammad.example.com',
          'Content-Description' => 'Rechnung_RE-2018-200.pdf',
          'Content-Disposition' => 'attachment',
        },
        created_by_id: 1,
      )

      authenticated_as(customer)
      get "/api/v1/ticket_split?ticket_id=#{ticket.id}&article_id=#{article.id}&form_id=new_form_id123", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)

      authenticated_as(agent)
      get "/api/v1/ticket_split?ticket_id=#{ticket.id}&article_id=#{article.id}&form_id=new_form_id123", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Ticket']).to be_truthy
      expect(json_response['assets']['Ticket'][ticket.id.to_s]).to be_truthy
      expect(json_response['assets']['TicketArticle'][article.id.to_s]).to be_truthy
      expect(json_response['attachments']).to be_truthy
      expect(json_response['attachments'].count).to eq(3)

      get "/api/v1/ticket_split?ticket_id=#{ticket.id}&article_id=#{article.id}&form_id=new_form_id123", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Ticket']).to be_truthy
      expect(json_response['assets']['Ticket'][ticket.id.to_s]).to be_truthy
      expect(json_response['assets']['TicketArticle'][article.id.to_s]).to be_truthy
      expect(json_response['attachments']).to be_truthy
      expect(json_response['attachments'].count).to eq(0)

    end

    it 'does ticket split with plain - check attachments (05.02)' do
      ticket = create(
        :ticket,
        title:         'some title',
        group:         ticket_group,
        customer_id:   customer.id,
        updated_by_id: agent.id,
        created_by_id: agent.id,
      )
      article = create(
        :ticket_article,
        type:         Ticket::Article::Type.lookup(name: 'note'),
        sender:       Ticket::Article::Sender.lookup(name: 'Customer'),
        body:         '<b>test</b> <img src="cid:15.274327094.140938@zammad.example.com"/>',
        content_type: 'text/plain',
        ticket_id:    ticket.id,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file1_normally_should_be_an_image',
        filename:      'some_file1.jpg',
        preferences:   {
          'Content-Type'        => 'image/jpeg',
          'Mime-Type'           => 'image/jpeg',
          'Content-ID'          => '15.274327094.140938@zammad.example.com',
          'Content-Disposition' => 'inline',
        },
        created_by_id: 1,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file1_normally_should_be_an_image',
        filename:      'some_file2.jpg',
        preferences:   {
          'Content-Type'        => 'image/jpeg',
          'Mime-Type'           => 'image/jpeg',
          'Content-ID'          => '15.274327094.140938.2@zammad.example.com',
          'Content-Disposition' => 'inline',
        },
        created_by_id: 1,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file1_normally_should_be_an_pdf',
        filename:      'Rechnung_RE-2018-200.pdf',
        preferences:   {
          'Content-Type'        => 'application/octet-stream; name="Rechnung_RE-2018-200.pdf"',
          'Mime-Type'           => 'application/octet-stream',
          'Content-ID'          => '8AB0BEC88984EE4EBEF643C79C8E0346@zammad.example.com',
          'Content-Description' => 'Rechnung_RE-2018-200.pdf',
          'Content-Disposition' => 'attachment',
        },
        created_by_id: 1,
      )

      authenticated_as(agent)
      get "/api/v1/ticket_split?ticket_id=#{ticket.id}&article_id=#{article.id}&form_id=new_form_id123", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Ticket']).to be_truthy
      expect(json_response['assets']['Ticket'][ticket.id.to_s]).to be_truthy
      expect(json_response['assets']['TicketArticle'][article.id.to_s]).to be_truthy
      expect(json_response['attachments']).to be_truthy
      expect(json_response['attachments'].count).to eq(3)

      get "/api/v1/ticket_split?ticket_id=#{ticket.id}&article_id=#{article.id}&form_id=new_form_id123", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Ticket']).to be_truthy
      expect(json_response['assets']['Ticket'][ticket.id.to_s]).to be_truthy
      expect(json_response['assets']['TicketArticle'][article.id.to_s]).to be_truthy
      expect(json_response['attachments']).to be_truthy
      expect(json_response['attachments'].count).to eq(0)

    end

    it 'does ticket merge (07.01)' do
      group_no_permission = create(:group)
      ticket1 = create(
        :ticket,
        title:       'ticket merge1',
        group:       ticket_group,
        customer_id: customer.id,
      )
      ticket2 = create(
        :ticket,
        title:       'ticket merge2',
        group:       ticket_group,
        customer_id: customer.id,
      )
      ticket3 = create(
        :ticket,
        title:       'ticket merge2',
        group:       group_no_permission,
        customer_id: customer.id,
      )

      authenticated_as(customer)
      put "/api/v1/ticket_merge/#{ticket2.id}/#{ticket1.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)

      authenticated_as(agent)
      put "/api/v1/ticket_merge/#{ticket2.id}/#{ticket1.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['result']).to eq('failed')
      expect(json_response['message']).to eq('No such master ticket number!')

      put "/api/v1/ticket_merge/#{ticket3.id}/#{ticket1.number}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized')
      expect(json_response['error_human']).to eq('Not authorized')

      put "/api/v1/ticket_merge/#{ticket1.id}/#{ticket3.number}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized')
      expect(json_response['error_human']).to eq('Not authorized')

      put "/api/v1/ticket_merge/#{ticket1.id}/#{ticket2.number}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['result']).to eq('success')
      expect(json_response['master_ticket']['id']).to eq(ticket2.id)
    end

    it 'does ticket merge - change permission (07.02)' do
      group_change_permission = Group.create!(
        name:          'GroupWithChangePermission',
        active:        true,
        updated_by_id: 1,
        created_by_id: 1,
      )
      ticket1 = create(
        :ticket,
        title:       'ticket merge1',
        group:       group_change_permission,
        customer_id: customer.id,
      )
      ticket2 = create(
        :ticket,
        title:       'ticket merge2',
        group:       group_change_permission,
        customer_id: customer.id,
      )

      agent.group_names_access_map = { group_change_permission.name => %w[read change] }

      authenticated_as(agent)
      put "/api/v1/ticket_merge/#{ticket1.id}/#{ticket2.number}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['result']).to eq('success')
      expect(json_response['master_ticket']['id']).to eq(ticket2.id)
    end

    it 'does ticket search sorted (08.01)' do
      title = "ticket pagination #{rand(999_999_999)}"

      ticket1 = create(
        :ticket,
        title:       "#{title} A",
        group:       ticket_group,
        customer_id: customer.id,
        created_at:  '2018-02-05 17:42:00',
        updated_at:  '2018-02-05 20:42:00',
      )
      create(
        :ticket_article,
        type:      Ticket::Article::Type.lookup(name: 'note'),
        sender:    Ticket::Article::Sender.lookup(name: 'Customer'),
        ticket_id: ticket1.id,
      )

      ticket2 = create(
        :ticket,
        title:       "#{title} B",
        group:       ticket_group,
        customer_id: customer.id,
        state:       Ticket::State.lookup(name: 'new'),
        priority:    Ticket::Priority.lookup(name: '3 hoch'),
        created_at:  '2018-02-05 19:42:00',
        updated_at:  '2018-02-05 19:42:00',
      )
      create(
        :ticket_article,
        type:      Ticket::Article::Type.lookup(name: 'note'),
        sender:    Ticket::Article::Sender.lookup(name: 'Customer'),
        ticket_id: ticket2.id,
      )

      authenticated_as(admin)
      get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets']).to eq([ticket2.id, ticket1.id])

      authenticated_as(admin)
      get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: { sort_by: 'created_at', order_by: 'asc' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets']).to eq([ticket1.id, ticket2.id])

      authenticated_as(admin)
      get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: { sort_by: 'title', order_by: 'asc' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets']).to eq([ticket1.id, ticket2.id])

      authenticated_as(admin)
      get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: { sort_by: 'title', order_by: 'desc' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets']).to eq([ticket2.id, ticket1.id])

      authenticated_as(admin)
      get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: { sort_by: %w[created_at updated_at], order_by: %w[asc asc] }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets']).to eq([ticket1.id, ticket2.id])

      authenticated_as(admin)
      get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: { sort_by: %w[created_at updated_at], order_by: %w[desc asc] }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['tickets']).to eq([ticket2.id, ticket1.id])
    end

    it 'does ticket history ' do
      ticket1 = create(
        :ticket,
        title:       'some title',
        group:       ticket_group,
        customer_id: customer.id,
      )
      create(
        :ticket_article,
        type:      Ticket::Article::Type.lookup(name: 'note'),
        sender:    Ticket::Article::Sender.lookup(name: 'Customer'),
        ticket_id: ticket1.id,
      )

      authenticated_as(agent)
      get "/api/v1/ticket_history/#{ticket1.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['history'].class).to eq(Array)
      expect(json_response['assets'].class).to eq(Hash)
      expect(json_response['assets']['User'][customer.id.to_s]).not_to be_nil
      expect(json_response['assets']['Ticket'][ticket1.id.to_s]).not_to be_nil

      authenticated_as(customer)
      get "/api/v1/ticket_history/#{ticket1.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'does ticket related' do
      ticket1 = create(
        :ticket,
        title:       'some title',
        group:       ticket_group,
        customer_id: customer.id,
      )

      authenticated_as(agent)
      get "/api/v1/ticket_related/#{ticket1.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      authenticated_as(customer)
      get "/api/v1/ticket_related/#{ticket1.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'does ticket recent' do
      authenticated_as(agent)
      get '/api/v1/ticket_recent', params: {}, as: :json
      expect(response).to have_http_status(:ok)

      authenticated_as(customer)
      get '/api/v1/ticket_recent', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
    end

  end

  describe 'mentions' do
    let(:user1) { create(:agent, groups: [ticket_group]) }
    let(:user2) { create(:agent, groups: [ticket_group]) }
    let(:user3) { create(:agent, groups: [ticket_group]) }

    def new_ticket_with_mentions
      params = {
        title:    'a new ticket #11',
        group:    ticket_group.name,
        customer: {
          firstname: 'some firstname',
          lastname:  'some lastname',
          email:     'some_new_customer@example.com',
        },
        article:  {
          body: 'some test 123',
        },
        mentions: [user1.id, user2.id, user3.id]
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)

      json_response
    end

    it 'create ticket with mentions' do
      new_ticket_with_mentions
      expect(Mention.all.count).to eq(3)
    end

    it 'check ticket get' do
      ticket = new_ticket_with_mentions

      get "/api/v1/tickets/#{ticket['id']}?all=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['mentions'].count).to eq(3)
      expect(json_response['assets']['Mention'].count).to eq(3)
    end
  end

  describe 'stats' do
    let(:ticket1) { create(:ticket, customer: customer, organization: organization, group: ticket_group) }
    let(:ticket2) { create(:ticket, customer: customer, organization: organization, group: ticket_group) }
    let(:ticket3) { create(:ticket, customer: customer, organization: organization, group: ticket_group) }
    let(:customer) { create(:customer, organization: organization) }
    let(:organization) { create(:organization, shared: false) }

    before do
      authenticated_as(admin)

      ticket1
      travel 2.minutes
      ticket2
      travel 2.minutes
      ticket3
      travel 2.minutes
      ticket2.touch
    end

    # https://github.com/zammad/zammad/issues/2296
    it 'orders tickets by created_at desc (#2296)' do
      get '/api/v1/ticket_stats', params: { organization_id: organization.id, user_id: customer.id }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response)
        .to be_a_kind_of(Hash)
        .and include('user' => hash_including('open_ids' => [ticket3.id, ticket2.id, ticket1.id]))
        .and include('organization' => hash_including('open_ids' => [ticket3.id, ticket2.id, ticket1.id]))
    end

  end

  describe '/api/v1/tickets' do
    subject(:ticket) { create(:ticket, state_name: 'closed') }

    let(:admin) { create(:admin, groups: [ticket.group]) }
    let(:agent) { create(:agent, groups: [ticket.group]) }
    let(:customer) { ticket.customer }

    describe 'reopening a ticket' do
      shared_examples 'successfully reopen a ticket' do
        it 'succeeds' do
          put "/api/v1/tickets/#{ticket.id}",
              params: { state_id: Ticket::State.find_by(name: 'open').id },
              as:     :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to include('state_id' => Ticket::State.find_by(name: 'open').id)
        end
      end

      shared_examples 'fail to reopen a ticket' do
        it 'fails' do
          put "/api/v1/tickets/#{ticket.id}",
              params: { state_id: Ticket::State.find_by(name: 'open').id },
              as:     :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response).to include('error' => 'Cannot follow-up on a closed ticket. Please create a new ticket.')
        end
      end

      context 'when ticket.group.follow_up_possible = "yes"' do
        before { ticket.group.update(follow_up_possible: 'yes') }

        context 'as admin', authenticated_as: -> { admin } do
          include_examples 'successfully reopen a ticket'
        end

        context 'as agent', authenticated_as: -> { agent } do
          include_examples 'successfully reopen a ticket'
        end

        context 'as customer', authenticated_as: -> { customer } do
          include_examples 'successfully reopen a ticket'
        end
      end

      context 'when ticket.group.follow_up_possible = "new_ticket"' do
        before { ticket.group.update(follow_up_possible: 'new_ticket') }

        context 'as admin', authenticated_as: -> { admin } do
          include_examples 'successfully reopen a ticket'
        end

        context 'as agent', authenticated_as: -> { agent } do
          include_examples 'successfully reopen a ticket'
        end

        context 'as customer', authenticated_as: -> { customer } do
          include_examples 'fail to reopen a ticket'
        end
      end
    end
  end

  describe 'GET /api/v1/tickets/:id' do

    subject!(:ticket) { create(:ticket) }

    let(:agent) { create(:agent, groups: [ticket.group]) }

    context 'links present', authenticated_as: -> { agent } do

      before do
        create(:link, from: ticket, to: linked)
        get "/api/v1/tickets/#{ticket.id}", params: { all: 'true' }, as: :json
      end

      let(:linked) { create(:ticket, group: ticket.group) }

      it 'is present in response' do
        expect(response).to have_http_status(:ok)
        expect(json_response['links']).to eq([
                                               {
                                                 'link_type'         => 'normal',
                                                 'link_object'       => 'Ticket',
                                                 'link_object_value' => linked.id
                                               }
                                             ])
      end

      context 'no permission to linked Ticket Group' do
        let(:linked) { create(:ticket) }

        it 'is not present in response' do
          expect(response).to have_http_status(:ok)
          expect(json_response['links']).to be_blank
        end
      end
    end
  end

  describe 'GET /api/v1/ticket_customer' do

    subject(:ticket) { create(:ticket, customer: customer_authorized) }

    let(:organization_authorized) { create(:organization) }
    let(:customer_authorized) { create(:customer, organization: organization_authorized) }

    let(:organization_unauthorized) { create(:organization) }
    let(:customer_unauthorized) { create(:customer, organization: organization_unauthorized) }

    let(:agent) { create(:agent, groups: [ticket.group]) }

    describe 'listing information' do

      before do
        ticket
      end

      shared_examples 'has access' do
        it 'succeeds' do
          get '/api/v1/ticket_customer',
              params: { customer_id: customer_authorized.id },
              as:     :json

          expect(json_response['ticket_ids_open']).to include(ticket.id)
          expect(json_response['ticket_ids_closed']).to be_blank
        end
      end

      shared_examples 'has no access' do
        it 'fails' do
          get '/api/v1/ticket_customer',
              params: { customer_id: customer_authorized.id },
              as:     :json

          expect(json_response['ticket_ids_open']).to be_blank
          expect(json_response['ticket_ids_closed']).to be_blank
          expect(json_response['assets']).to be_blank
        end
      end

      context 'as agent', authenticated_as: -> { agent } do
        include_examples 'has access'
      end

      context 'as authorized customer', authenticated_as: -> { customer_authorized } do
        include_examples 'has no access'
      end

      context 'as unauthorized customer', authenticated_as: -> { customer_unauthorized } do
        include_examples 'has no access'
      end
    end
  end
end
