# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::SessionId, type: :graphql do

  context 'when checking the SessionID' do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        query sessionId {
          sessionId
        }
      QUERY
    end

    before do
      gql.execute(query)
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'has data' do
        expect(gql.result.data).to be_present
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
