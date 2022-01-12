# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::SessionId, type: :graphql do

  context 'when checking the SessionID' do
    let(:agent) { create(:agent) }
    let(:query) { read_graphql_file('common/graphql/queries/sessionId.graphql') }

    before do
      graphql_execute(query)
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'has data' do
        expect(graphql_response['data']['sessionId']).to be_present
      end
    end

    include_examples 'graphql responds with error if unauthenticated'
  end
end
