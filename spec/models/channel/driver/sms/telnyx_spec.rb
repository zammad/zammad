# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Sms::Telnyx, sms_telnyx: true do
  let(:signing_key) { OpenSSL::PKey.generate_key('ED25519') }
  let(:public_key)  { telnyx_public_key(signing_key) }
  let(:channel)     { create(:sms_telnyx_channel, public_key: public_key) }
  let(:driver)      { channel.driver_instance.new }

  describe '#deliver' do
    let(:api_url)   { 'https://api.telnyx.com/v2/messages' }
    let(:recipient) { '+37060010000' }
    let(:deliver)   { driver.deliver(channel.options, { recipient: recipient, message: 'Test' }) }

    let(:accepted_response) do
      {
        data: {
          record_type: 'message',
          id:          '40385f64-5717-4562-b3fc-2c963f66afa6',
          from:        { phone_number: channel.options[:sender] },
          to:          [{ phone_number: recipient, status: 'queued' }],
          text:        'Test',
        }
      }.to_json
    end

    it 'posts the message as JSON with bearer authentication', :aggregate_failures do
      request = stub_request(:post, api_url)
        .with(
          body:    { from: channel.options[:sender], to: recipient, text: 'Test' },
          headers: {
            'Authorization' => "Bearer #{channel.options[:token]}",
            'Content-Type'  => 'application/json; charset=utf-8',
          }
        )
        .to_return(status: 200, body: accepted_response, headers: { 'Content-Type' => 'application/json' })

      expect(deliver).to be true
      expect(request).to have_been_requested
    end

    it 'raises with the API error details' do
      stub_request(:post, api_url)
        .to_return(status: 422, body: { errors: [{ code: '40310', title: 'Invalid phone number', detail: 'The to number is not valid.' }] }.to_json)

      expect { deliver }.to raise_error(RuntimeError, 'Telnyx API error (HTTP 422): 40310 - Invalid phone number - The to number is not valid.')
    end

    it 'keeps the HTTP error when the error body is not JSON' do
      stub_request(:post, api_url).to_return(status: 503, body: '<html>Service Unavailable</html>')

      expect { deliver }.to raise_error(RuntimeError, %r{\ATelnyx API error \(HTTP 503\): Server Error})
    end

    it 'keeps the HTTP error when the error body has an unexpected JSON shape' do
      stub_request(:post, api_url).to_return(status: 401, body: '["unauthorized"]')

      expect { deliver }.to raise_error(RuntimeError, %r{\ATelnyx API error \(HTTP 401\): Client Error})
    end

    it 'raises when the accepted response carries no message id' do
      stub_request(:post, api_url).to_return(status: 200, body: '{"data":{}}', headers: { 'Content-Type' => 'application/json' })

      expect { deliver }.to raise_error(RuntimeError, 'Telnyx API error (HTTP 200): response does not contain an accepted message id')
    end

    it 'does not follow a redirect with the API key', :aggregate_failures do
      stub_request(:post, api_url).to_return(status: 302, headers: { 'Location' => 'https://other.example.com/v2/messages' })
      redirect_target = stub_request(:any, 'https://other.example.com/v2/messages')

      expect { deliver }.to raise_error(RuntimeError, %r{redirect})
      expect(redirect_target).not_to have_been_requested
    end

    it 'does not call the API in import mode', :aggregate_failures do
      Setting.set('import_mode', true)

      expect(deliver).to be true
      expect(a_request(:post, api_url)).not_to have_been_made
    end

    it 'does not call the API in developer mode', :aggregate_failures do
      Setting.set('developer_mode', true)

      expect(deliver).to be true
      expect(a_request(:post, api_url)).not_to have_been_made
    end
  end

  describe '#process' do
    let(:raw_body)   { telnyx_webhook_body(:inbound_sms1) }
    let(:timestamp)  { Time.zone.now.to_i }
    let(:signature)  { telnyx_webhook_signature(raw_body, timestamp: timestamp, key: signing_key) }
    let(:attributes) { webhook_attributes(raw_body, signature: signature, timestamp: timestamp) }
    let(:process)    { driver.process(channel.options, attributes, channel) }

    before { UserInfo.current_user_id = 1 }

    shared_examples 'rejecting the webhook' do |error_class, message|
      it "raises #{error_class} without creating records" do
        expect { process }
          .to raise_error(error_class, message)
          .and not_change(Ticket, :count)
          .and not_change(User, :count)
      end
    end

    context 'with a correctly signed inbound message' do
      it 'creates a ticket with the article from the signed body', :aggregate_failures do
        expect { process }.to change(Ticket, :count).by(1).and change(Ticket::Article, :count).by(1)

        ticket  = Ticket.last
        article = Ticket::Article.last

        expect(ticket).to have_attributes(
          title:    'Ldfhxhcuffufuf. Fifififig.  Fifififiif F...',
          group_id: channel.group_id,
        )
        expect(ticket.preferences['sms']).to eq(
          'messaging_profile_id' => '740572b6-099c-44a1-89b9-6c92163bc68d',
          'from'                 => '+491710000000',
          'to'                   => '+4915700000000',
        )
        expect(article).to have_attributes(
          from:         '+491710000000',
          to:           '+4915700000000',
          body:         'Ldfhxhcuffufuf. Fifififig.  Fifififiif Fifififiif Fifififiif Fifififiif Fifififiif',
          message_id:   '84cca175-9755-4859-b67f-4730d7f58001',
          content_type: 'text/plain',
        )
        expect(article.sender.name).to eq('Customer')
        expect(article.type.name).to eq('sms')
        expect(article.preferences['sms']).to include('type' => 'SMS', 'media' => [])
      end

      it 'acknowledges with an empty JSON response' do
        expect(process).to eq([:json, {}])
      end

      it 'suppresses a retried delivery of the same message' do
        process

        expect { driver.process(channel.options, attributes, channel) }
          .to not_change(Ticket::Article, :count)
          .and not_change(Ticket, :count)
      end

      it 'accepts a timestamp at the edge of the tolerance' do
        attributes = webhook_attributes(raw_body, signature: telnyx_webhook_signature(raw_body, timestamp: timestamp - 299, key: signing_key), timestamp: timestamp - 299)

        expect { driver.process(channel.options, attributes, channel) }.to change(Ticket, :count).by(1)
      end

      context 'when unsigned request params try to override the signed body' do
        let(:attributes) do
          webhook_attributes(
            raw_body,
            signature: signature,
            timestamp: timestamp,
            params:    { 'data' => { 'event_type' => 'message.received', 'payload' => { 'text' => 'tampered', 'from' => { 'phone_number' => '+10000000000' } } } },
          )
        end

        it 'only uses the signed body' do
          process

          expect(Ticket::Article.last).to have_attributes(
            body: 'Ldfhxhcuffufuf. Fifififig.  Fifififiif Fifififiif Fifififiif Fifififiif Fifififiif',
            from: '+491710000000',
          )
        end
      end

      context 'when the article cannot be created' do
        before do
          allow(Ticket::Article).to receive(:create!).and_raise(ActiveRecord::RecordNotSaved, 'article failed')
        end

        include_examples 'rejecting the webhook', ActiveRecord::RecordNotSaved, 'article failed'
      end
    end

    context 'with a media-only inbound message' do
      let(:raw_body) { telnyx_webhook_body(:inbound_mms1) }

      it 'creates the article with an empty body and the media list', :aggregate_failures do
        expect { process }.to change(Ticket, :count).by(1)

        expect(Ticket.last.title).to eq('')
        expect(Ticket::Article.last).to have_attributes(body: '', message_id: '84cca175-9755-4859-b67f-4730d7f58004')
        expect(Ticket::Article.last.preferences['sms']).to include(
          'type'  => 'MMS',
          'media' => [include('content_type' => 'image/jpeg', 'url' => 'https://media.telnyx.com/XXXXXX')],
        )
      end
    end

    context 'with signed events that are not inbound messages' do
      %i[message_sent message_finalized].each do |event|
        context "when the event is #{event}" do
          let(:raw_body) { telnyx_webhook_body(event) }

          it 'acknowledges without creating records', :aggregate_failures do
            expect { process }.to not_change(Ticket, :count).and not_change(User, :count)
            expect(process).to eq([:json, {}])
          end
        end
      end
    end

    context 'when the request is not a POST' do
      let(:attributes) { webhook_attributes(raw_body, signature: signature, timestamp: timestamp, request_method: 'GET') }

      include_examples 'rejecting the webhook', Exceptions::Forbidden, 'Telnyx webhooks are only accepted via POST.'
    end

    context 'when the signature header is missing' do
      let(:signature) { nil }

      include_examples 'rejecting the webhook', Exceptions::Forbidden, 'Telnyx webhook signature headers are missing.'
    end

    context 'when the timestamp header is missing' do
      let(:attributes) { webhook_attributes(raw_body, signature: signature, timestamp: nil) }

      include_examples 'rejecting the webhook', Exceptions::Forbidden, 'Telnyx webhook signature headers are missing.'
    end

    context 'when the request body is empty' do
      let(:attributes) { webhook_attributes('', signature: signature, timestamp: timestamp) }

      include_examples 'rejecting the webhook', Exceptions::Forbidden, 'Telnyx webhook request body is missing.'
    end

    context 'when the body was tampered with after signing' do
      let(:attributes) do
        webhook_attributes(raw_body.sub('Ldfhxhcuffufuf', 'Tampered'), signature: signature, timestamp: timestamp)
      end

      include_examples 'rejecting the webhook', Exceptions::Forbidden, 'Telnyx webhook signature is invalid.'
    end

    context 'when the body was signed with another key' do
      let(:signature) { telnyx_webhook_signature(raw_body, timestamp: timestamp, key: OpenSSL::PKey.generate_key('ED25519')) }

      include_examples 'rejecting the webhook', Exceptions::Forbidden, 'Telnyx webhook signature is invalid.'
    end

    context 'when the signature is not base64' do
      let(:signature) { '%%%not-base64%%%' }

      include_examples 'rejecting the webhook', Exceptions::Forbidden, 'Telnyx webhook signature is invalid.'
    end

    context 'when the timestamp does not match the signed one' do
      let(:attributes) { webhook_attributes(raw_body, signature: signature, timestamp: timestamp + 1) }

      include_examples 'rejecting the webhook', Exceptions::Forbidden, 'Telnyx webhook signature is invalid.'
    end

    context 'when the timestamp is stale' do
      let(:timestamp) { Time.zone.now.to_i - 301 }

      include_examples 'rejecting the webhook', Exceptions::Forbidden, 'Telnyx webhook timestamp is outside of the accepted tolerance.'
    end

    context 'when the timestamp is in the future' do
      let(:timestamp) { Time.zone.now.to_i + 301 }

      include_examples 'rejecting the webhook', Exceptions::Forbidden, 'Telnyx webhook timestamp is outside of the accepted tolerance.'
    end

    context 'when the timestamp is malformed' do
      let(:timestamp) { 'yesterday' }

      include_examples 'rejecting the webhook', Exceptions::Forbidden, 'Telnyx webhook timestamp is invalid.'
    end

    context 'when the channel has no public key' do
      let(:channel) { create(:sms_telnyx_channel, public_key: nil) }

      include_examples 'rejecting the webhook', Exceptions::UnprocessableContent, 'Telnyx public key is missing in the channel configuration.'
    end

    context 'when the channel public key is not base64' do
      let(:channel) { create(:sms_telnyx_channel, public_key: 'not a key') }

      include_examples 'rejecting the webhook', Exceptions::UnprocessableContent, 'Telnyx public key in the channel configuration is invalid.'
    end

    context 'when the channel public key has the wrong length' do
      let(:channel) { create(:sms_telnyx_channel, public_key: Base64.strict_encode64(SecureRandom.random_bytes(16))) }

      include_examples 'rejecting the webhook', Exceptions::UnprocessableContent, 'Telnyx public key in the channel configuration is invalid.'
    end

    context 'with a correctly signed but malformed payload' do
      {
        'not JSON'                    => 'hello',
        'a JSON array'                => '[]',
        'a scalar data element'       => '{"data":"x"}',
        'no event type'               => '{"data":{"payload":{}}}',
        'a scalar payload'            => '{"data":{"event_type":"message.received","payload":"x"}}',
        'no message id'               => '{"data":{"event_type":"message.received","payload":{"from":{"phone_number":"+491710000000"},"to":[{"phone_number":"+4915700000000"}],"text":"Hi"}}}',
        'a scalar from element'       => '{"data":{"event_type":"message.received","payload":{"id":"1","from":"+491710000000","to":[{"phone_number":"+4915700000000"}],"text":"Hi"}}}',
        'a scalar to element'         => '{"data":{"event_type":"message.received","payload":{"id":"1","from":{"phone_number":"+491710000000"},"to":"+4915700000000","text":"Hi"}}}',
        'an empty to list'            => '{"data":{"event_type":"message.received","payload":{"id":"1","from":{"phone_number":"+491710000000"},"to":[],"text":"Hi"}}}',
        'a non-string text'           => '{"data":{"event_type":"message.received","payload":{"id":"1","from":{"phone_number":"+491710000000"},"to":[{"phone_number":"+4915700000000"}],"text":123}}}',
        'a non-list media element'    => '{"data":{"event_type":"message.received","payload":{"id":"1","from":{"phone_number":"+491710000000"},"to":[{"phone_number":"+4915700000000"}],"text":"","media":"x"}}}',
        'neither text nor media'      => '{"data":{"event_type":"message.received","payload":{"id":"1","from":{"phone_number":"+491710000000"},"to":[{"phone_number":"+4915700000000"}],"text":"","media":[]}}}',
        'no text and no media fields' => '{"data":{"event_type":"message.received","payload":{"id":"1","from":{"phone_number":"+491710000000"},"to":[{"phone_number":"+4915700000000"}]}}}',
      }.each do |description, body|
        context "when the body is #{description}" do
          let(:raw_body) { body }

          include_examples 'rejecting the webhook', Exceptions::UnprocessableContent, 'Telnyx webhook payload is invalid.'
        end
      end
    end

    def webhook_attributes(body, signature:, timestamp:, request_method: 'POST', params: {})
      params.merge(
        raw_body:       body,
        request_method: request_method,
        headers:        {
          'telnyx-signature-ed25519' => signature,
          'telnyx-timestamp'         => timestamp&.to_s,
        }.compact,
      ).with_indifferent_access
    end
  end
end
