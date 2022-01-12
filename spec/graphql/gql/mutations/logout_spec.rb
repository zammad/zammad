# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Login and logout work only via controller, so use type: request.
RSpec.describe Gql::Mutations::Logout, type: :request do

  context 'when logging out' do
    let(:agent) { create(:agent) }
    let(:query) { File.read(Rails.root.join('app/frontend/common/graphql/mutations/logout.graphql')) }
    let(:graphql_response) do
      post '/graphql', params: { query: query }, as: :json
      json_response
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'logs out' do
        expect(graphql_response['data']['logout']).to eq('success' => true)
      end
    end

    include_examples 'graphql responds with error if unauthenticated'

    context 'without authenticated session and missing CSRF token', allow_forgery_protection: true do
      it 'fails with error message, not with CSRF validation failed' do
        expect(graphql_response['errors'][0]['message']).to eq('Authentication required')
      end

      it 'fails with error type, not with CSRF validation failed' do
        expect(graphql_response['errors'][0]['extensions']).to include({ 'type' => 'Exceptions::NotAuthorized' })
      end
    end
  end
end
