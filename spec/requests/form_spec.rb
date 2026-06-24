# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Form', type: :request do

  describe 'request handling' do

    it 'does get config call' do
      post '/api/v1/form_config', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Not authorized')
    end

    it 'does get config call with form_ticket_create' do
      Setting.set('form_ticket_create', true)
      post '/api/v1/form_config', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Not authorized')

    end

    it 'does get config call & do submit' do
      Setting.set('form_ticket_create', true)
      fingerprint = SecureRandom.hex(40)
      post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['enabled']).to be(true)
      expect(json_response['endpoint']).to eq('http://zammad.example.com/api/v1/form_submit')
      expect(json_response['token']).to be_truthy
      token = json_response['token']

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: 'invalid' }, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Authorization failed')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['name']).to eq('required')
      expect(json_response['errors']['email']).to eq('required')
      expect(json_response['errors']['title']).to eq('required')
      expect(json_response['errors']['body']).to eq('required')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, email: 'some' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['name']).to eq('required')
      expect(json_response['errors']['email']).to eq('invalid')
      expect(json_response['errors']['title']).to eq('required')
      expect(json_response['errors']['body']).to eq('required')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test', body: 'hello' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_falsey
      expect(json_response['ticket']).to be_truthy
      expect(json_response['ticket']['id']).to be_truthy
      expect(json_response['ticket']['number']).to be_truthy

      travel 5.hours

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test', body: 'hello' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_falsey
      expect(json_response['ticket']).to be_truthy
      expect(json_response['ticket']['id']).to be_truthy
      expect(json_response['ticket']['number']).to be_truthy

      travel 20.hours

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test', body: 'hello' }, as: :json
      expect(response).to have_http_status(:unauthorized)

    end

    it 'does get config call & do submit - second test' do
      Setting.set('form_ticket_create', true)
      fingerprint = SecureRandom.hex(40)
      post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['enabled']).to be(true)
      expect(json_response['endpoint']).to eq('http://zammad.example.com/api/v1/form_submit')
      expect(json_response['token']).to be_truthy
      token = json_response['token']

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: 'invalid' }, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Authorization failed')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['name']).to eq('required')
      expect(json_response['errors']['email']).to eq('required')
      expect(json_response['errors']['title']).to eq('required')
      expect(json_response['errors']['body']).to eq('required')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, email: 'some' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['name']).to eq('required')
      expect(json_response['errors']['email']).to eq('invalid')
      expect(json_response['errors']['title']).to eq('required')
      expect(json_response['errors']['body']).to eq('required')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'somebody@somedomainthatisinvalid.com', title: 'test', body: 'hello' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['email']).to eq('invalid')

    end

    it 'does limits', :rack_attack do
      Setting.set('form_ticket_create_by_ip_per_hour', 2)
      Setting.set('form_ticket_create', true)
      fingerprint = SecureRandom.hex(40)

      post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['token']).to be_truthy
      token = json_response['token']

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test', body: 'hello' }, as: :json
      expect(response).to have_http_status(:ok)

      3.times do |count|
        post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: "test#{count}", body: 'hello' }, as: :json
      end
      expect(response).to have_http_status(:too_many_requests)

      @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json', 'REMOTE_ADDR' => '1.2.3.5' }
      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test-2', body: 'hello' }, as: :json
      expect(response).to have_http_status(:ok)

      3.times do |count|
        post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: "test-2-#{count}", body: 'hello' }, as: :json
      end
      expect(response).to have_http_status(:too_many_requests)

      @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json', 'REMOTE_ADDR' => '::1' }
      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test-3', body: 'hello' }, as: :json

      3.times do |count|
        post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: "test-3-#{count}", body: 'hello' }, as: :json
      end
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'does customer_ticket_create false disables form' do
      Setting.set('form_ticket_create', false)
      Setting.set('customer_ticket_create', true)

      fingerprint = SecureRandom.hex(40)

      post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json

      token = json_response['token']
      params = {
        fingerprint: fingerprint,
        token:       token,
        name:        'Bob Smith',
        email:       'discard@zammad.com',
        title:       'test',
        body:        'hello'
      }

      post '/api/v1/form_submit', params: params, as: :json

      expect(response).to have_http_status(:forbidden)
    end

    describe 'spam protection' do
      let(:fingerprint) { SecureRandom.hex(40) }
      let(:token)       { json_response['token'] }

      before do
        Setting.set('form_ticket_create', true)
        post '/api/v1/form_config', params: { fingerprint: }, as: :json
      end

      def submit(extra = {})
        post '/api/v1/form_submit', params: {
          fingerprint:,
          token:,
          name:        'Bob Smith',
          email:       'discard@zammad.com',
          title:       'test',
          body:        'hello',
        }.merge(extra), as: :json
      end

      it 'exposes the honeypot configuration via form_config' do
        expect(json_response.dig('spam_protection', 'honeypot', 'field')).to eq(FormSpamProtection::Honeypot::FIELD_NAME)
      end

      it 'rejects submissions that fill in the honeypot field' do
        submit(FormSpamProtection::Honeypot::FIELD_NAME => 'http://spam.example.com')

        expect(response).to have_http_status(:ok)
        expect(json_response.dig('errors', 'spam')).to be_present
        expect(json_response['ticket']).to be_nil
      end

      context 'with a configured captcha provider' do
        before do
          Setting.set('form_ticket_create_captcha_provider', 'turnstile')
          Setting.set('form_ticket_create_captcha_options', { 'sitekey' => 'k', 'secret' => 's' })
          allow(UserAgent).to receive(:post).and_return(
            instance_double(UserAgent::Result, success?: true, code: 200, body: { success: captcha_success }.to_json)
          )
        end

        context 'when the captcha verification fails' do
          let(:captcha_success) { false }

          it 'rejects the submission' do
            submit('cf-turnstile-response': 'token')

            expect(json_response.dig('errors', 'spam')).to be_present
            expect(json_response['ticket']).to be_nil
          end
        end

        context 'when the captcha verification succeeds' do
          let(:captcha_success) { true }

          it 'creates the ticket' do
            submit('cf-turnstile-response': 'token')

            expect(json_response.dig('ticket', 'number')).to be_present
          end
        end

        context 'when a field is invalid' do
          let(:captcha_success) { true }

          it 'returns the field error without consuming the captcha', :aggregate_failures do
            submit('cf-turnstile-response': 'token', email: 'invalid')

            expect(json_response.dig('errors', 'email')).to be_present
            expect(json_response.dig('errors', 'spam')).to be_nil
            expect(UserAgent).not_to have_received(:post)
          end
        end

        context 'when the honeypot is filled in' do
          let(:captcha_success) { true }

          it 'rejects via the honeypot without verifying the captcha', :aggregate_failures do
            submit('cf-turnstile-response': 'token', FormSpamProtection::Honeypot::FIELD_NAME => 'spam')

            expect(json_response.dig('errors', 'spam')).to be_present
            expect(json_response['ticket']).to be_nil
            expect(UserAgent).not_to have_received(:post)
          end
        end
      end

      # ALTCHA verifies in-process (no external service), so the full flow can be
      # exercised end-to-end: fetch a challenge, solve it like the browser widget
      # would, submit, and create a ticket.
      context 'with the ALTCHA provider (proof-of-work, verified in-process)' do
        before do
          Setting.set('form_ticket_create_captcha_provider', 'altcha')
          token # memoize the form token before the challenge request replaces the response
        end

        def solved_altcha
          get '/api/v1/form_captcha_challenge', as: :json
          expect(response).to have_http_status(:ok)

          challenge = json_response
          expect(challenge).to include('maxnumber', 'salt', 'challenge')

          number = (0..challenge['maxnumber']).find { |n| Digest::SHA256.hexdigest("#{challenge['salt']}#{n}") == challenge['challenge'] }

          Base64.strict_encode64({
            algorithm: challenge['algorithm'],
            challenge: challenge['challenge'],
            number:,
            salt:      challenge['salt'],
            signature: challenge['signature'],
          }.to_json)
        end

        it 'creates a ticket for a correctly solved challenge', :aggregate_failures do
          submit(altcha: solved_altcha)

          expect(json_response.dig('errors', 'spam')).to be_nil
          expect(json_response.dig('ticket', 'number')).to be_present
        end

        it 'rejects a submission with no solved challenge', :aggregate_failures do
          submit

          expect(json_response.dig('errors', 'spam')).to be_present
          expect(json_response['ticket']).to be_nil
        end

        it 'rejects a replayed solution', :aggregate_failures do
          payload = solved_altcha

          submit(altcha: payload)
          expect(json_response.dig('ticket', 'number')).to be_present

          submit(altcha: payload)
          expect(json_response.dig('errors', 'spam')).to be_present
        end
      end
    end

    describe 'CAPTCHA challenge endpoint' do
      it 'serves a signed challenge for a provider that issues one (ALTCHA)', :aggregate_failures do
        Setting.set('form_ticket_create', true)
        Setting.set('form_ticket_create_captcha_provider', 'altcha')
        get '/api/v1/form_captcha_challenge', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('algorithm' => 'SHA-256')
        expect(json_response['salt']).to be_present
        expect(json_response['signature']).to be_present
      end

      it 'is not found when the provider issues no server-side challenge' do
        Setting.set('form_ticket_create', true)
        Setting.set('form_ticket_create_captcha_provider', 'turnstile')
        get '/api/v1/form_captcha_challenge', as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'is forbidden when the form is disabled' do
        Setting.set('form_ticket_create', false)
        get '/api/v1/form_captcha_challenge', as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'form_allowed_params Setting', db_strategy: :reset do
      let(:fingerprint) { SecureRandom.hex(40) }
      let(:token)       { json_response['token'] }
      let(:ticket)      { Ticket.find json_response.dig('ticket', 'id') }
      let(:custom_attr) { create(:object_manager_attribute_text) }

      before do
        custom_attr
        ObjectManager::Attribute.migration_execute

        Setting.set('form_allowed_params', form_allowed_params)
        Setting.set('form_ticket_create', true)
        post '/api/v1/form_config', params: { fingerprint: }, as: :json

        post '/api/v1/form_submit', params: {
          fingerprint:,
          token:,
          name:  'Bob Smith',
          email: 'discard@zammad.com',
          title: 'test-last',
          body:  'hello',
          custom_attr.name => 'some note'
        }, as: :json
      end

      context 'when blank' do
        let(:form_allowed_params) { [] }

        it 'rejects additional parameters' do
          expect(ticket).to have_attributes(custom_attr.name => be_blank)
        end
      end

      context 'when present' do
        let(:form_allowed_params) { [custom_attr.name] }

        it 'allows additional parameters' do
          expect(ticket).to have_attributes(custom_attr.name => 'some note')
        end
      end
    end

    context 'when ApplicationHandleInfo context' do
      let(:fingerprint) { SecureRandom.hex(40) }
      let(:token)       { json_response['token'] }

      before do
        allow(ApplicationHandleInfo).to receive('context=')
        Setting.set('form_ticket_create', true)
        post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json
      end

      it 'gets switched to "form"' do
        post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test-last', body: 'hello' }, as: :json
        expect(ApplicationHandleInfo).to have_received('context=').with('form').at_least(1)
      end

      it 'reverts back to default' do
        post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test-last', body: 'hello' }, as: :json
        expect(ApplicationHandleInfo.context).not_to eq 'form'
      end

      context 'when form_allowed_params is not blank' do
        before do
          Setting.set('form_allowed_params', %w[note])
        end

        it 'does not switch context to "form"' do
          post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test-last', body: 'hello' }, as: :json
          expect(ApplicationHandleInfo).not_to have_received('context=').with('form')
        end
      end
    end
  end
end
