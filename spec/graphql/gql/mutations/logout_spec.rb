# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Login and logout work only via controller, so use type: request.
RSpec.describe Gql::Mutations::Logout, type: :request do

  context 'when logging out' do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        mutation logout {
          logout {
            success
            externalLogoutUrl
          }
        }
      QUERY
    end
    let(:graphql_response) do
      post '/graphql', params: { query: query }, as: :json
      json_response
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'logs out' do
        expect(graphql_response['data']['logout']).to eq('success' => true, 'externalLogoutUrl' => nil)
      end
    end

    context 'with authenticated session, but in maintenance_mode', authenticated_as: :agent do
      before do
        Setting.set('maintenance_mode', true)
      end

      it 'logs out' do
        expect(graphql_response['data']['logout']).to eq('success' => true, 'externalLogoutUrl' => nil)
      end
    end

    context 'without authenticated session', authenticated_as: false do
      it 'logs out' do
        expect(graphql_response['data']['logout']).to eq('success' => true, 'externalLogoutUrl' => nil)
      end
    end

    context 'without authenticated session and missing CSRF token', allow_forgery_protection: true do
      it 'logs out, does not fail not with CSRF validation failed' do
        expect(graphql_response['data']['logout']).to eq('success' => true, 'externalLogoutUrl' => nil)
      end
    end
  end
end
