# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Twilio SMS', performs_jobs: true, type: :request do
  describe 'request handling' do
    let(:group) { create(:group) }
    let(:agent) { create(:agent, groups: [group]) }

    let(:channel) do
      create(
        :channel,
        area:     'Sms::Account',
        options:  {
          adapter:       'sms/twilio',
          webhook_token: 'secret_webhook_token',
          account_id:    '111',
          token:         '223',
          sender:        '333',
        },
        group_id: group&.id,
      )
    end

    before do
      channel
      UserInfo.current_user_id = 1
    end

    it 'does basic call' do
      post '/api/v1/sms_webhook/secret_webhook_token', params: read_message('inbound_sms1'), as: :json
      expect(response).to have_http_status(:ok)
      xml_response = REXML::Document.new(response.body)
      expect(xml_response.elements.count).to eq(1)

      ticket = Ticket.last
      article = Ticket::Article.last
      customer = User.last
      expect(ticket.articles.count).to eq(1)
      expect(ticket.title).to eq('Ldfhxhcuffufuf. Fifififig.  Fifififiif F...')
      expect(ticket.state.name).to eq('new')
      expect(ticket.group_id).to eq(group.id)
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

      post '/api/v1/sms_webhook/secret_webhook_token', params: read_message('inbound_sms2'), as: :json
      expect(response).to have_http_status(:ok)
      xml_response = REXML::Document.new(response.body)
      expect(xml_response.elements.count).to eq(1)

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
      post '/api/v1/sms_webhook/secret_webhook_token', params: read_message('inbound_sms2'), as: :json
      expect(response).to have_http_status(:ok)
      xml_response = REXML::Document.new(response.body)
      expect(xml_response.elements.count).to eq(1)

      ticket.reload
      expect(ticket.articles.count).to eq(2)
      expect(ticket.state.name).to eq('new')
      expect(article.id).to eq(Ticket::Article.last.id)

      # new ticket needs to be created
      ticket.state = Ticket::State.find_by(name: 'closed')
      ticket.save!

      post '/api/v1/sms_webhook/secret_webhook_token', params: read_message('inbound_sms3'), as: :json
      expect(response).to have_http_status(:ok)
      xml_response = REXML::Document.new(response.body)
      expect(xml_response.elements.count).to eq(1)

      ticket.reload
      expect(ticket.articles.count).to eq(2)
      expect(ticket.id).not_to eq(Ticket.last.id)
      expect(ticket.state.name).to eq('closed')

      ticket = Ticket.last
      article = Ticket::Article.last
      customer = User.last
      expect(ticket.articles.count).to eq(1)
      expect(ticket.title).to eq('new 2')
      expect(ticket.group_id).to eq(group.id)
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

    context 'when channel is not configured correctly' do
      let(:group) { nil }

      it 'does basic call' do
        # process inbound sms
        post '/api/v1/sms_webhook', params: read_message('inbound_sms1'), as: :json
        expect(response).to have_http_status(:not_found)

        post '/api/v1/sms_webhook/not_existing', params: read_message('inbound_sms1'), as: :json
        expect(response).to have_http_status(:not_found)

        post '/api/v1/sms_webhook/secret_webhook_token', params: read_message('inbound_sms1'), as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Sms::Twilio: Group needed in channel definition! (Exceptions::UnprocessableEntity)')
      end
    end

    context 'when customer is based on already existing mobile attribute' do
      let(:group) { Group.first }

      it 'does basic call' do
        customer = create(
          :customer,
          email:  'me@example.com',
          mobile: '01710000000',
        )

        perform_enqueued_jobs commit_transaction: true

        post '/api/v1/sms_webhook/secret_webhook_token', params: read_message('inbound_sms1'), as: :json
        expect(response).to have_http_status(:ok)
        xml_response = REXML::Document.new(response.body)
        expect(xml_response.elements.count).to eq(1)

        expect(customer.id).to eq(User.last.id)
      end
    end

    context 'when ticket has a custom attribute' do
      let(:group) { Group.first }

      it 'does basic call', db_strategy: :reset do
        create(:object_manager_attribute_text, :required_screen)
        ObjectManager::Attribute.migration_execute

        post '/api/v1/sms_webhook/secret_webhook_token', params: read_message('inbound_sms1'), as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when incoming message is of an unsupported type (#5289)' do
      it 'does basic call' do
        post '/api/v1/sms_webhook/secret_webhook_token', params: read_message('inbound_sms4'), as: :json
        expect(response).to have_http_status(:ok)
        xml_response = REXML::Document.new(response.body)
        expect(xml_response.elements.count).to eq(1)

        ticket = Ticket.last
        article = Ticket::Article.last
        customer = User.last
        expect(ticket.articles.count).to eq(1)
        expect(ticket.title).to eq('')
        expect(ticket.state.name).to eq('new')
        expect(ticket.group_id).to eq(group.id)
        expect(ticket.customer_id).to eq(customer.id)
        expect(ticket.created_by_id).to eq(customer.id)
        expect(article.from).to eq('+491710000000')
        expect(article.to).to eq('+4915700000000')
        expect(article.cc).to be_nil
        expect(article.subject).to be_nil
        expect(article.body).to eq('')
        expect(article.created_by_id).to eq(customer.id)
        expect(article.sender.name).to eq('Customer')
        expect(article.type.name).to eq('sms')
      end
    end

    def read_message(file)
      JSON.parse(Rails.root.join('test', 'data', 'twilio', "#{file}.json").read)
    end
  end
end
