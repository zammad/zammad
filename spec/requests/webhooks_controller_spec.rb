# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe WebhooksController, type: :request do
  let(:agent) { create(:agent) }
  let(:admin) { create(:admin) }

  describe 'request handling', authenticated_as: :admin do
    context 'when listing webhooks' do
      let!(:webhooks) { create_list(:webhook, 10, signature_token: 'some_token', basic_auth_password: 'some_password', bearer_token: 'some_token') }
      let(:url) { '/api/v1/webhooks.json' }

      before do
        get url
      end

      context 'without parameters' do

        it 'returns all' do
          expect(json_response.length).to eq(webhooks.length)
        end

        it 'masks sensitive fields' do
          expect(json_response.first).to include(
            'signature_token'     => SensitiveParamsHelper::SENSITIVE_MASK,
            'basic_auth_password' => SensitiveParamsHelper::SENSITIVE_MASK,
            'bearer_token'        => SensitiveParamsHelper::SENSITIVE_MASK
          )
        end

        context 'with agent permissions', authenticated_as: :agent do
          it 'request is forbidden' do
            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      context 'with expand=1' do
        let(:url) { '/api/v1/webhooks.json?expand=1' }

        it 'returns all' do
          expect(json_response.length).to eq(webhooks.length)
        end

        it 'masks sensitive fields' do
          expect(json_response.first).to include(
            'signature_token'     => SensitiveParamsHelper::SENSITIVE_MASK,
            'basic_auth_password' => SensitiveParamsHelper::SENSITIVE_MASK,
          )

        end
      end

      context 'with full=1' do
        let(:url) { '/api/v1/webhooks.json?full=1' }

        it 'returns all' do
          expect(json_response['record_ids'].length).to eq(webhooks.length)
        end

        it 'masks sensitive fields' do
          expect(json_response['assets']['Webhook'][webhooks.first.id.to_s]).to include(
            'signature_token'     => SensitiveParamsHelper::SENSITIVE_MASK,
            'basic_auth_password' => SensitiveParamsHelper::SENSITIVE_MASK,
          )
        end
      end
    end

    context 'when showing webhook' do
      let!(:webhook) { create(:webhook, signature_token: 'some_token', basic_auth_password: 'some_password') }

      before do
        get "/api/v1/webhooks/#{webhook.id}.json"
      end

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      context 'with inactive template' do
        let!(:webhook) { create(:webhook, active: false) }

        it 'returns ok' do
          expect(response).to have_http_status(:ok)
        end
      end

      it 'masks sensitive fields' do
        expect(json_response).to include(
          'signature_token'     => SensitiveParamsHelper::SENSITIVE_MASK,
          'basic_auth_password' => SensitiveParamsHelper::SENSITIVE_MASK,
        )
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when creating webhook' do
      before do
        post '/api/v1/webhooks.json', params: { name: 'Foo', endpoint: 'http://example.com/endpoint', ssl_verify: true, active: true }
      end

      it 'returns created' do
        expect(response).to have_http_status(:created)
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when updating webhook' do
      let!(:webhook) { create(:webhook, signature_token: 'some_token', basic_auth_password: 'some_password') }
      let(:params)   { { name: 'Foo' } }

      before do
        put "/api/v1/webhooks/#{webhook.id}.json", params:
      end

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      context 'with masked fields' do
        let(:params) do
          {
            name:                'Foo',
            signature_token:     SensitiveParamsHelper::SENSITIVE_MASK,
            basic_auth_password: SensitiveParamsHelper::SENSITIVE_MASK,
          }
        end

        it 'returns ok' do
          expect(response).to have_http_status(:ok)
        end

        it 'masks sensitive fields' do
          expect(json_response).to include(
            'signature_token'     => SensitiveParamsHelper::SENSITIVE_MASK,
            'basic_auth_password' => SensitiveParamsHelper::SENSITIVE_MASK,
          )
        end

        it 'keeps field values' do
          expect(webhook.reload).to have_attributes(signature_token: 'some_token', basic_auth_password: 'some_password')
        end
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when destroying webhook' do
      let!(:webhook) { create(:webhook) }

      before do
        delete "/api/v1/webhooks/#{webhook.id}.json"
      end

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when fetching pre-defined webhooks' do
      before do
        get '/api/v1/webhooks/pre_defined.json'
      end

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns an array' do
        expect(json_response).to be_an_instance_of(Array)
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when fetching custom payload replacements' do
      before do
        get '/api/v1/webhooks/payload/replacements.json'
      end

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns a hash' do
        expect(json_response).to be_an_instance_of(Hash)
      end

      it 'returns no webhook variables by default' do
        expect(json_response).not_to include('webhook')
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "when the pre-defined webhook type 'Mattermost' is used" do
        before do
          get '/api/v1/webhooks/payload/replacements?pre_defined_webhook_type=Mattermost'
        end

        it 'returns webhook variables' do
          expect(json_response).to include('webhook' => %w[messaging_username messaging_channel messaging_icon_url])
        end
      end

      context "when the pre-defined webhook type 'Slack' is used" do
        before do
          get '/api/v1/webhooks/payload/replacements?pre_defined_webhook_type=Slack'
        end

        it 'returns no webhook variables' do
          expect(json_response).not_to include('webhook')
        end
      end
    end
  end
end
