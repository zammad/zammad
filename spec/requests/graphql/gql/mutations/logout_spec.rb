# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

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
        expect(graphql_response['data']['logout']).to eq({ 'success' => true })
      end
    end

    context 'without authenticated session' do
      it 'fails with error message' do
        expect(graphql_response['errors'][0]['message']).to eq('Authentication required by Gql::Mutations::Logout')
      end

      it 'fails with error type' do
        expect(graphql_response['errors'][0]['extensions']).to include({ 'type' => 'Exceptions::NotAuthorized' })
      end
    end
  end
end
