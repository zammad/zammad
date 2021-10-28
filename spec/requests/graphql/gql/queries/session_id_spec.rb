# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::SessionId, type: :request do

  context 'when checking the SessionID' do
    let(:agent) { create(:agent) }
    let(:query) { File.read(Rails.root.join('app/frontend/apps/mobile/graphql/queries/sessionId.graphql')) }
    let(:graphql_response) do
      post '/graphql', params: { query: query }, as: :json
      json_response
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'has data' do
        expect(graphql_response['data']['sessionId']).to be_present
      end
    end

    context 'without authenticated session', authenticated_as: false do
      it 'fails' do
        expect(graphql_response['errors'][0]['message']).to eq('The field sessionId on an object of type Queries was hidden due to permissions')
      end
    end
  end
end
