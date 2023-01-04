# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Login and logout work only via controller, so use type: request.
RSpec.describe Gql::Mutations::Logout, type: :request do

  # Temporary Hack: skip tests if ENABLE_EXPERIMENTAL_MOBILE_FRONTEND is not set.
  # TODO: Remove when this switch is not needed any more.
  around do |example|
    example.run if ENV['ENABLE_EXPERIMENTAL_MOBILE_FRONTEND'] == 'true'
  end

  context 'when logging out' do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        mutation logout {
          logout {
            success
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
        expect(graphql_response['data']['logout']).to eq('success' => true)
      end
    end

    context 'with authenticated session, but in maintenance_mode', authenticated_as: :agent do
      before do
        Setting.set('maintenance_mode', true)
      end

      it 'logs out' do
        expect(graphql_response['data']['logout']).to eq('success' => true)
      end
    end

    context 'without authenticated session', authenticated_as: false do
      it 'logs out' do
        expect(graphql_response['data']['logout']).to eq('success' => true)
      end
    end

    context 'without authenticated session and missing CSRF token', allow_forgery_protection: true do
      it 'logs out, does not fail not with CSRF validation failed' do
        expect(graphql_response['data']['logout']).to eq('success' => true)
      end
    end
  end
end
