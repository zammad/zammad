# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Session, type: :graphql do

  context 'when checking the Session' do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        query session {
          session {
            id
            afterAuth {
              type
              data
            }
          }
        }
      QUERY
    end

    before do
      allow_any_instance_of(Auth::AfterAuth::TwoFactorConfiguration).to receive(:check).and_return(true)
      gql.execute(query, context: { controller: instance_double(GraphqlController, session: { authentication_type: 'password' }) })
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'returns session id' do
        expect(gql.result.data[:id]).to be_present
      end

      it 'returns after_auth data' do
        expect(gql.result.data[:afterAuth]).to eq({ 'type' => 'TwoFactorConfiguration', 'data' => {} })
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
