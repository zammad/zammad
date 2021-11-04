# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::SessionId, type: :request do

  context 'when checking the SessionID' do
    let(:agent) { create(:agent) }
    let(:query) { File.read(Rails.root.join('app/frontend/common/graphql/queries/sessionId.graphql')) }
    let(:graphql_response) do
      post '/graphql', params: { query: query }, as: :json
      json_response
    end

    context 'with authenticated session, CRSF checking disabled', authenticated_as: :agent do
      it 'has data' do
        expect(graphql_response['data']['sessionId']).to be_present
      end
    end

    context 'with authenticated session, CRSF checking enabled but inactive due to basic_auth usage', authenticated_as: :agent, allow_forgery_protection: true do
      it 'has data' do
        expect(graphql_response['data']['sessionId']).to be_present
      end
    end

    context 'with authenticated session, but missing CSRF token', allow_forgery_protection: true do
      it 'fails with error message' do
        expect(graphql_response['errors'][0]['message']).to eq('CSRF token verification failed!')
      end

      it 'fails with error type' do
        expect(graphql_response['errors'][0]['extensions']).to include({ 'type' => 'Exceptions::NotAuthorized' })
      end
    end

    context 'without authenticated session', authenticated_as: false do
      it 'fails with error message' do
        expect(graphql_response['errors'][0]['message']).to eq('Authentication required by Gql::Queries::SessionId')
      end

      it 'fails with error type' do
        expect(graphql_response['errors'][0]['extensions']).to include({ 'type' => 'Exceptions::NotAuthorized' })
      end
    end
  end
end
