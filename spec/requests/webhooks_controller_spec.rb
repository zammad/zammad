# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Webhook, type: :request do
  let(:agent) { create(:agent) }
  let(:admin) { create(:admin) }

  describe 'request handling', authenticated_as: :admin do
    context 'when listing webhooks' do
      let!(:webhooks) { create_list(:webhook, 10) }

      it 'returns all' do
        get '/api/v1/webhooks.json'

        expect(json_response.length).to eq(webhooks.length)
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          get '/api/v1/webhooks.json'

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when showing webhook' do
      let!(:webhook) { create(:webhook) }

      it 'returns ok' do
        get "/api/v1/webhooks/#{webhook.id}.json"

        expect(response).to have_http_status(:ok)
      end

      context 'with inactive template' do
        let!(:inactive_webhook) { create(:webhook, active: false) }

        it 'returns ok' do
          get "/api/v1/webhooks/#{inactive_webhook.id}.json"

          expect(response).to have_http_status(:ok)
        end
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          get "/api/v1/webhooks/#{webhook.id}.json"

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when creating webhook' do
      it 'returns created' do
        post '/api/v1/webhooks.json', params: { name: 'Foo', endpoint: 'http://example.com/endpoint', ssl_verify: true, active: true }

        expect(response).to have_http_status(:created)
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          post '/api/v1/webhooks.json', params: { name: 'Foo', endpoint: 'http://example.com/endpoint', ssl_verify: true, active: true }

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when updating webhook' do
      let!(:webhook) { create(:webhook) }

      it 'returns ok' do
        put "/api/v1/webhooks/#{webhook.id}.json", params: { name: 'Foo' }

        expect(response).to have_http_status(:ok)
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          put "/api/v1/webhooks/#{webhook.id}.json", params: { name: 'Foo' }

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when destroying webhook' do
      let!(:webhook) { create(:webhook) }

      it 'returns ok' do
        delete "/api/v1/webhooks/#{webhook.id}.json"

        expect(response).to have_http_status(:ok)
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          delete "/api/v1/webhooks/#{webhook.id}.json"

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when fetching custom payload replacements' do
      it 'returns ok' do
        get '/api/v1/webhooks/payload/replacements.json'

        expect(response).to have_http_status(:ok)
      end

      it 'returns a hash' do
        get '/api/v1/webhooks/payload/replacements.json'

        expect(json_response).to be_an_instance_of(Hash)
      end

      context 'with agent permissions', authenticated_as: :agent do
        it 'request is forbidden' do
          get '/api/v1/webhooks/payload/replacements.json'

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
