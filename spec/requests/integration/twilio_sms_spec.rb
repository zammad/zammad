# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Twilio SMS', type: :request, performs_jobs: true do

  describe 'request handling' do

    let(:agent) do
      create(:agent, groups: Group.all)
    end

    it 'does basic call' do

      # configure twilio channel
      group_id = Group.find_by(name: 'Users').id

      UserInfo.current_user_id = 1
      channel = create(
        :channel,
        area:     'Sms::Account',
        options:  {
          adapter:       'sms/twilio',
          webhook_token: 'f409460e50f76d331fdac8ba7b7963b6',
          account_id:    '111',
          token:         '223',
          sender:        '333',
        },
        group_id: nil,
      )

      # process inbound sms
      post '/api/v1/sms_webhook', params: read_message('inbound_sms1'), as: :json
      expect(response).to have_http_status(:not_found)

      post '/api/v1/sms_webhook/not_existing', params: read_message('inbound_sms1'), as: :json
      expect(response).to have_http_status(:not_found)

      post '/api/v1/sms_webhook/f409460e50f76d331fdac8ba7b7963b6', params: read_message('inbound_sms1'), as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect('Can\'t use Channel::Driver::Sms::Twilio: #<Exceptions::UnprocessableEntity: Group needed in channel definition!>').to eq(json_response['error'])

      channel.group_id = Group.first.id
      channel.save!

      post '/api/v1/sms_webhook/f409460e50f76d331fdac8ba7b7963b6', params: read_message('inbound_sms1'), as: :json
      expect(response).to have_http_status(:ok)
      xml_response = REXML::Document.new(response.body)
      expect(1).to eq(xml_response.elements.count)

      ticket = Ticket.last
      article = Ticket::Article.last
      customer = User.last
      expect(ticket.articles.count).to eq(1)
      expect(ticket.title).to eq('Ldfhxhcuffufuf. Fifififig.  Fifififiif F...')
      expect(ticket.state.name).to eq('new')
      expect(ticket.group_id).to eq(group_id)
      expect(ticket.customer_id).to eq(customer.id)
      expect(ticket.created_by_id).to eq(customer.id)
      expect(article.from).to eq('+491710000000')
      expect(article.to).to eq('+4915700000000')
      expect(article.cc).to be_nil
      expect(article.subject).to be_nil
      expect(article.body).to eq('Ldfhxhcuffufuf. Fifififig.  Fifififiif Fifififiif Fifififiif Fifififiif Fifififiif')
      expect(article.created_by_id).to eq(customer.id)
      expect(article.sender.name).to eq('Customer')
      expect(article.type.name).to eq('sms')

      post '/api/v1/sms_webhook/f409460e50f76d331fdac8ba7b7963b6', params: read_message('inbound_sms2'), as: :json
      expect(response).to have_http_status(:ok)
      xml_response = REXML::Document.new(response.body)
      expect(1).to eq(xml_response.elements.count)

      ticket.reload
      expect(ticket.articles.count).to eq(2)
      expect(ticket.state.name).to eq('new')

      article = Ticket::Article.last
      expect(article.from).to eq('+491710000000')
      expect(article.to).to eq('+4915700000000')
      expect(article.cc).to be_nil
      expect(article.subject).to be_nil
      expect(article.body).to eq('Follow-up')
      expect(article.sender.name).to eq('Customer')
      expect(article.type.name).to eq('sms')
      expect(article.created_by_id).to eq(customer.id)

      # check duplicate callbacks
      post '/api/v1/sms_webhook/f409460e50f76d331fdac8ba7b7963b6', params: read_message('inbound_sms2'), as: :json
      expect(response).to have_http_status(:ok)
      xml_response = REXML::Document.new(response.body)
      expect(1).to eq(xml_response.elements.count)

      ticket.reload
      expect(ticket.articles.count).to eq(2)
      expect(ticket.state.name).to eq('new')
      expect(article.id).to eq(Ticket::Article.last.id)

      # new ticket needs to be created
      ticket.state = Ticket::State.find_by(name: 'closed')
      ticket.save!

      post '/api/v1/sms_webhook/f409460e50f76d331fdac8ba7b7963b6', params: read_message('inbound_sms3'), as: :json
      expect(response).to have_http_status(:ok)
      xml_response = REXML::Document.new(response.body)
      expect(1).to eq(xml_response.elements.count)

      ticket.reload
      expect(ticket.articles.count).to eq(2)
      expect(ticket.id).not_to eq(Ticket.last.id)
      expect(ticket.state.name).to eq('closed')

      ticket = Ticket.last
      article = Ticket::Article.last
      customer = User.last
      expect(ticket.articles.count).to eq(1)
      expect(ticket.title).to eq('new 2')
      expect(ticket.group_id).to eq(group_id)
      expect(ticket.customer_id).to eq(customer.id)
      expect(ticket.created_by_id).to eq(customer.id)
      expect(article.from).to eq('+491710000000')
      expect(article.to).to eq('+4915700000000')
      expect(article.cc).to be_nil
      expect(article.subject).to be_nil
      expect(article.body).to eq('new 2')
      expect(article.created_by_id).to eq(customer.id)
      expect(article.sender.name).to eq('Customer')
      expect(article.type.name).to eq('sms')

      # reply by agent
      params = {
        ticket_id: ticket.id,
        body:      'some test',
        type:      'sms',
      }
      authenticated_as(agent)
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some test')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      stub_request(:post, 'https://api.twilio.com/2010-04-01/Accounts/111/Messages.json')
        .with(
          body:    {
            'Body' => 'some test',
            'From' => '333',
            'To'   => nil,
          },
          headers: {
            'Accept'         => 'application/json',
            'Accept-Charset' => 'utf-8',
            'Authorization'  => 'Basic MTExOjIyMw==',
            'Content-Type'   => 'application/x-www-form-urlencoded',
          }
        ).to_return(status: 200, body: '', headers: {})

      expect(article.preferences[:delivery_retry]).to be_nil
      expect(article.preferences[:delivery_status]).to be_nil

      perform_enqueued_jobs commit_transaction: true

      article = Ticket::Article.find(json_response['id'])
      expect(article.preferences[:delivery_retry]).to eq(1)
      expect(article.preferences[:delivery_status]).to eq('success')

    end

    it 'does customer based on already existing mobile attibute' do

      customer = create(
        :customer,
        email:  'me@example.com',
        mobile: '01710000000',
      )

      perform_enqueued_jobs commit_transaction: true

      UserInfo.current_user_id = 1
      create(
        :channel,
        area:    'Sms::Account',
        options: {
          adapter:       'sms/twilio',
          webhook_token: 'f409460e50f76d331fdac8ba7b7963b6',
          account_id:    '111',
          token:         '223',
          sender:        '333',
        },
      )

      post '/api/v1/sms_webhook/f409460e50f76d331fdac8ba7b7963b6', params: read_message('inbound_sms1'), as: :json
      expect(response).to have_http_status(:ok)
      xml_response = REXML::Document.new(response.body)
      expect(1).to eq(xml_response.elements.count)

      expect(customer.id).to eq(User.last.id)
    end

    it 'does basic call when ticket has a custom attribute', db_strategy: :reset do
      create(:object_manager_attribute_text, screens: attributes_for(:required_screen))
      ObjectManager::Attribute.migration_execute

      UserInfo.current_user_id = 1
      create(
        :channel,
        area:     'Sms::Account',
        options:  {
          adapter:       'sms/twilio',
          webhook_token: 'f409460e50f76d331fdac8ba7b7963b6',
          account_id:    '111',
          token:         '223',
          sender:        '333',
        },
        group_id: Group.first.id,
      )

      post '/api/v1/sms_webhook/f409460e50f76d331fdac8ba7b7963b6', params: read_message('inbound_sms1'), as: :json
      expect(response).to have_http_status(:ok)
    end

    def read_message(file)
      JSON.parse(Rails.root.join('test', 'data', 'twilio', "#{file}.json").read)
    end
  end
end
