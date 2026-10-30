# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Telnyx SMS', performs_jobs: true, sms_telnyx: true, type: :request do
  describe 'request handling' do
    let(:group)       { create(:group) }
    let(:agent)       { create(:agent, groups: [group]) }
    let(:signing_key) { OpenSSL::PKey.generate_key('ED25519') }
    let(:public_key)  { telnyx_public_key(signing_key) }
    let(:api_url)     { 'https://api.telnyx.com/v2/messages' }

    let(:channel) do
      create(
        :sms_telnyx_channel,
        public_key:    public_key,
        webhook_token: 'secret_webhook_token',
        group:         group,
      )
    end

    before do
      channel
      add_headers('Accept' => 'application/json')
      UserInfo.current_user_id = 1
    end

    it 'creates a ticket for the first message of a customer', :aggregate_failures do
      post_webhook(:inbound_sms1)
      expect(response).to have_http_status(:ok)

      ticket   = Ticket.last
      article  = Ticket::Article.last
      customer = User.last

      expect(customer.mobile).to eq('+491710000000')
      expect(ticket).to have_attributes(
        title:         'Ldfhxhcuffufuf. Fifififig.  Fifififiif F...',
        group_id:      group.id,
        customer_id:   customer.id,
        created_by_id: customer.id,
      )
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(1)
      expect(ticket.preferences['channel_id']).to eq(channel.id)
      expect(article).to have_attributes(
        from:          '+491710000000',
        to:            '+4915700000000',
        cc:            nil,
        subject:       nil,
        body:          'Ldfhxhcuffufuf. Fifififig.  Fifififiif Fifififiif Fifififiif Fifififiif Fifififiif',
        message_id:    '84cca175-9755-4859-b67f-4730d7f58001',
        created_by_id: customer.id,
      )
      expect(article.sender.name).to eq('Customer')
      expect(article.type.name).to eq('sms')
      expect(channel.reload.status_in).to eq('ok')
    end

    it 'verifies the exact UTF-8 body bytes including JSON whitespace', :aggregate_failures do
      body = JSON.pretty_generate(telnyx_webhook_event(:inbound_sms1, text: 'Grüße 👋'))
      post '/api/v1/sms_webhook/secret_webhook_token', params: body, headers: signed_headers(body)

      expect(response).to have_http_status(:ok)
      expect(Ticket::Article.last.body).to eq('Grüße 👋')
    end

    it 'threads a follow-up into the open ticket and suppresses retried webhooks', :aggregate_failures do
      post_webhook(:inbound_sms1)
      ticket = Ticket.last

      post_webhook(:inbound_sms2)
      expect(response).to have_http_status(:ok)
      expect(ticket.reload.articles.count).to eq(2)
      expect(ticket.state.name).to eq('new')

      article = Ticket::Article.last
      expect(article).to have_attributes(from: '+491710000000', to: '+4915700000000', body: 'Follow-up', created_by_id: ticket.customer_id)
      expect(article.sender.name).to eq('Customer')

      post_webhook(:inbound_sms2)
      expect(response).to have_http_status(:ok)
      expect(ticket.reload.articles.count).to eq(2)
      expect(Ticket::Article.last.id).to eq(article.id)
    end

    it 'creates a new ticket when the previous one is closed', :aggregate_failures do
      post_webhook(:inbound_sms1)
      ticket = Ticket.last
      ticket.update!(state: Ticket::State.find_by(name: 'closed'))

      post_webhook(:inbound_sms3)
      expect(response).to have_http_status(:ok)
      expect(ticket.reload.articles.count).to eq(1)
      expect(ticket.state.name).to eq('closed')

      new_ticket = Ticket.last
      expect(new_ticket.id).not_to eq(ticket.id)
      expect(new_ticket).to have_attributes(title: 'new 2', group_id: group.id, customer_id: ticket.customer_id, created_by_id: ticket.customer_id)
      expect(new_ticket.articles.count).to eq(1)
      expect(Ticket::Article.last).to have_attributes(body: 'new 2', created_by_id: ticket.customer_id)
    end

    it 'delivers agent replies via the Telnyx API', :aggregate_failures do
      post_webhook(:inbound_sms1)
      ticket = Ticket.last

      authenticated_as(agent)
      post '/api/v1/ticket_articles', params: { ticket_id: ticket.id, body: 'some test', type: 'sms', to: '+491710000000' }, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to include('subject' => nil, 'body' => 'some test', 'content_type' => 'text/plain', 'created_by_id' => agent.id)

      api_request = stub_request(:post, api_url)
        .with(
          body:    { 'from' => channel.options[:sender], 'to' => '+491710000000', 'text' => 'some test' },
          headers: {
            'Authorization' => "Bearer #{channel.options[:token]}",
            'Content-Type'  => 'application/json; charset=utf-8',
          }
        ).to_return(status: 200, body: accepted_response, headers: { 'Content-Type' => 'application/json' })

      article = Ticket::Article.find(json_response['id'])
      expect(article.preferences[:delivery_status]).to be_nil

      perform_enqueued_jobs commit_transaction: true

      article.reload
      expect(article.preferences[:delivery_retry]).to eq(1)
      expect(article.preferences[:delivery_status]).to eq('success')
      expect(api_request).to have_been_requested
    end

    context 'when channel is not configured correctly' do
      let(:group) { nil }

      it 'does basic call', :aggregate_failures do
        post '/api/v1/sms_webhook', params: telnyx_webhook_body(:inbound_sms1), headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to have_http_status(:not_found)

        post_webhook(:inbound_sms1, token: 'not_existing')
        expect(response).to have_http_status(:not_found)

        expect { post_webhook(:inbound_sms1) }.to not_change(Ticket, :count).and not_change(User, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('Sms::Telnyx: Group needed in channel definition! (Exceptions::UnprocessableContent)')
      end
    end

    context 'when customer is based on already existing mobile attribute' do
      let(:group) { Group.first }

      it 'does basic call', :aggregate_failures do
        customer = create(
          :customer,
          email:  'me@example.com',
          mobile: '01710000000',
        )

        perform_enqueued_jobs commit_transaction: true

        post_webhook(:inbound_sms1)
        expect(response).to have_http_status(:ok)

        expect(customer.id).to eq(User.last.id)
        expect(Ticket.last.customer_id).to eq(customer.id)
      end
    end

    context 'when ticket has a custom attribute' do
      let(:group) { Group.first }

      it 'does basic call', db_strategy: :reset do
        create(:object_manager_attribute_text, :required_screen)
        ObjectManager::Attribute.migration_execute

        post_webhook(:inbound_sms1)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when incoming message carries media only' do
      it 'creates the ticket with an empty article body', :aggregate_failures do
        post_webhook(:inbound_mms1)
        expect(response).to have_http_status(:ok)

        ticket   = Ticket.last
        article  = Ticket::Article.last
        customer = User.last

        expect(ticket).to have_attributes(title: '', group_id: group.id, customer_id: customer.id)
        expect(ticket.state.name).to eq('new')
        expect(ticket.articles.count).to eq(1)
        expect(article).to have_attributes(from: '+491710000000', to: '+4915700000000', body: '')
        expect(article.sender.name).to eq('Customer')
        expect(article.type.name).to eq('sms')
        expect(article.preferences['sms']['type']).to eq('MMS')
        expect(article.preferences['sms']['media'].first['content_type']).to eq('image/jpeg')
      end
    end

    context 'when a signed event is not an inbound message' do
      %i[message_sent message_finalized].each do |event|
        it "acknowledges #{event} without creating a ticket", :aggregate_failures do
          expect { post_webhook(event) }.to not_change(Ticket, :count).and not_change(User, :count)
          expect(response).to have_http_status(:ok)
          expect(channel.reload.status_in).to eq('ok')
        end
      end
    end

    context 'when the request is not signed' do
      it 'rejects the request and marks the channel', :aggregate_failures do
        expect { post '/api/v1/sms_webhook/secret_webhook_token', params: telnyx_webhook_body(:inbound_sms1), headers: { 'CONTENT_TYPE' => 'application/json' } }
          .to not_change(Ticket, :count).and not_change(User, :count)

        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Sms::Telnyx: Telnyx webhook signature headers are missing. (Exceptions::Forbidden)')
        expect(channel.reload.status_in).to eq('error')
        expect(channel.last_log_in).to include('signature headers are missing')
      end

      it 'rejects the request when sent as JSON params without signature headers', :aggregate_failures do
        expect { post '/api/v1/sms_webhook/secret_webhook_token', params: JSON.parse(telnyx_webhook_body(:inbound_sms1)), as: :json }
          .to not_change(Ticket, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the signature does not match' do
      it 'rejects a body that was tampered with after signing', :aggregate_failures do
        body    = telnyx_webhook_body(:inbound_sms1)
        headers = signed_headers(body)

        expect { post '/api/v1/sms_webhook/secret_webhook_token', params: body.sub('Ldfhxhcuffufuf', 'Tampered'), headers: headers }
          .to not_change(Ticket, :count)

        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Sms::Telnyx: Telnyx webhook signature is invalid. (Exceptions::Forbidden)')
      end

      it 'rejects a body signed with another key', :aggregate_failures do
        expect { post_webhook(:inbound_sms1, key: OpenSSL::PKey.generate_key('ED25519')) }.to not_change(Ticket, :count)

        expect(response).to have_http_status(:forbidden)
      end

      it 'rejects a stale timestamp', :aggregate_failures do
        expect { post_webhook(:inbound_sms1, timestamp: Time.zone.now.to_i - 301) }.to not_change(Ticket, :count)

        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Sms::Telnyx: Telnyx webhook timestamp is outside of the accepted tolerance. (Exceptions::Forbidden)')
      end

      it 'rejects a timestamp from the future', :aggregate_failures do
        expect { post_webhook(:inbound_sms1, timestamp: Time.zone.now.to_i + 301) }.to not_change(Ticket, :count)

        expect(response).to have_http_status(:forbidden)
      end

      it 'rejects a malformed timestamp', :aggregate_failures do
        expect { post_webhook(:inbound_sms1, timestamp: 'yesterday') }.to not_change(Ticket, :count)

        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Sms::Telnyx: Telnyx webhook timestamp is invalid. (Exceptions::Forbidden)')
      end
    end

    context 'when the webhook is called via GET' do
      it 'rejects the request', :aggregate_failures do
        body = telnyx_webhook_body(:inbound_sms1)

        expect { get '/api/v1/sms_webhook/secret_webhook_token', headers: signed_headers(body) }.to not_change(Ticket, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when unsigned query params accompany a signed body' do
      it 'only uses the signed body', :aggregate_failures do
        body = telnyx_webhook_body(:inbound_sms1)

        post '/api/v1/sms_webhook/secret_webhook_token?data[payload][text]=tampered', params: body, headers: signed_headers(body)
        expect(response).to have_http_status(:ok)
        expect(Ticket::Article.last.body).to eq('Ldfhxhcuffufuf. Fifififig.  Fifififiif Fifififiif Fifififiif Fifififiif Fifififiif')
      end
    end

    context 'when the channel public key is not configured' do
      let(:channel) do
        create(:sms_telnyx_channel, public_key: nil, webhook_token: 'secret_webhook_token', group: group)
      end

      it 'rejects the request with a configuration error', :aggregate_failures do
        expect { post_webhook(:inbound_sms1) }.to not_change(Ticket, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('Sms::Telnyx: Telnyx public key is missing in the channel configuration. (Exceptions::UnprocessableContent)')
        expect(channel.reload.status_in).to eq('error')
      end
    end

    context 'when a signed payload is malformed' do
      it 'rejects a payload without an inbound message structure', :aggregate_failures do
        body = '{"data":{"event_type":"message.received","payload":{"from":"+491710000000"}}}'

        expect { post '/api/v1/sms_webhook/secret_webhook_token', params: body, headers: signed_headers(body) }
          .to not_change(Ticket, :count).and not_change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('Sms::Telnyx: Telnyx webhook payload is invalid. (Exceptions::UnprocessableContent)')
      end

      it 'rejects an inbound message without text and media', :aggregate_failures do
        body = telnyx_webhook_body(:inbound_sms1, text: '')

        expect { post '/api/v1/sms_webhook/secret_webhook_token', params: body, headers: signed_headers(body) }
          .to not_change(Ticket, :count).and not_change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'rejects a body that is not JSON', :aggregate_failures do
        body = 'this is not json'

        expect { post '/api/v1/sms_webhook/secret_webhook_token', params: body, headers: signed_headers(body) }
          .to not_change(Ticket, :count)

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when testing the provider as an administrator', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      it 'sends the configured message through the admin endpoint', :aggregate_failures do
        api_request = stub_request(:post, api_url)
          .with(body: { from: channel.options[:sender], to: '+491710000000', text: 'Test message' })
          .to_return(status: 200, body: accepted_response)

        post '/api/v1/channels_sms/test', params: { options: channel.options, recipient: '+491710000000', message: 'Test message' }, as: :json

        expect(json_response).to eq('success' => true)
        expect(api_request).to have_been_requested.once
      end
    end

    it 'delivers trigger notifications through a notification channel', :aggregate_failures do
      notification = create(:sms_telnyx_channel, area: 'Sms::Notification', token: 'notification-api-key', custom_options: { public_key: nil })
      create(:trigger,
             disable_notification: false,
             condition:            { 'ticket.group_id' => { 'operator' => 'is', 'value' => group.id.to_s } },
             perform:              { 'notification.sms' => { recipient: 'ticket_customer', body: 'Ticket received' } })
      api_request = stub_request(:post, api_url)
        .with(
          body:    { from: notification.options[:sender], to: '+491710000000', text: 'Ticket received' },
          headers: { 'Authorization' => 'Bearer notification-api-key' },
        ).to_return(status: 200, body: accepted_response)

      post_webhook(:inbound_sms1)
      expect(response).to have_http_status(:ok)
      perform_enqueued_jobs commit_transaction: true

      article = Ticket.last.articles.find_by(sender: Ticket::Article::Sender.find_by(name: 'System'), type: Ticket::Article::Type.find_by(name: 'sms'))
      expect(article.preferences['channel_id']).to eq(notification.id)
      expect(article.preferences['delivery_status']).to eq('success')
      expect(api_request).to have_been_requested.once
    end

    def signed_headers(body, timestamp: Time.zone.now.to_i, key: signing_key)
      {
        'CONTENT_TYPE'             => 'application/json',
        'ACCEPT'                   => 'application/json',
        'telnyx-timestamp'         => timestamp.to_s,
        'telnyx-signature-ed25519' => telnyx_webhook_signature(body, timestamp: timestamp, key: key),
      }
    end

    def post_webhook(event, token: 'secret_webhook_token', **)
      body = telnyx_webhook_body(event)
      post "/api/v1/sms_webhook/#{token}", params: body, headers: signed_headers(body, **)
    end

    def accepted_response
      {
        data: {
          record_type: 'message',
          id:          '40385f64-5717-4562-b3fc-2c963f66afa6',
          from:        { phone_number: channel.options[:sender] },
          to:          [{ phone_number: '+491710000000', status: 'queued' }],
          text:        'some test',
        }
      }.to_json
    end
  end
end
