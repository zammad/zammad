# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'GettingStarted', :aggregate_failures, type: :request do
  describe 'GET /api/v1/getting_started' do
    context 'when system is not yet set up' do
      it 'returns setup status without authentication' do
        get '/api/v1/getting_started', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          'setup_done' => false,
        )
      end
    end

    context 'when system is already set up' do
      let(:admin) { create(:admin) }

      before do
        # setup_done requires more than 2 users to consider setup complete
        create(:agent)
      end

      context 'when not authenticated' do
        it 'returns forbidden' do
          get '/api/v1/getting_started', as: :json

          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when authenticated', authenticated_as: :admin do
        it 'returns detailed setup information' do
          get '/api/v1/getting_started', as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to include(
            'setup_done'     => true,
            'groups'         => be_a(Array),
            'addresses'      => be_a(Array),
            'config'         => be_a(Hash),
            'channel_driver' => be_a(Hash),
          )
        end
      end
    end
  end

  describe 'GET /api/v1/getting_started/auto_wizard' do
    context 'when system is already set up' do
      let(:admin) { create(:admin) }

      before { create(:agent) }

      it 'returns forbidden when not authenticated' do
        get '/api/v1/getting_started/auto_wizard', as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/getting_started/base' do
    let(:admin) { create(:admin) }

    before { create(:agent) }

    context 'when not authenticated' do
      it 'returns forbidden' do
        post '/api/v1/getting_started/base', params: { url: 'https://example.com' }, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      before { authenticated_as(admin, via: :browser) }

      it 'sets system base information' do
        post '/api/v1/getting_started/base', params: { url: 'https://example.com', locale_default: 'en-us', timezone_default: 'UTC', organization: 'Test Corp' }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('result' => 'ok')
      end

      it 'returns error for missing url' do
        post '/api/v1/getting_started/base', params: { locale_default: 'en-us' }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('result' => 'invalid')
      end
    end

    context 'when authenticated as agent' do
      let(:agent) { create(:agent) }

      before { authenticated_as(agent, via: :browser) }

      it 'returns forbidden' do
        post '/api/v1/getting_started/base', params: { url: 'https://example.com' }, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
