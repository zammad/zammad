# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    let(:session) { ActionController::TestSession.new(authentication_type: 'password') }
    let(:context) { { controller: instance_double(GraphqlController, session:) } }

    before do
      allow_any_instance_of(Auth::AfterAuth::TwoFactorConfiguration).to receive(:check).and_return(true)
      gql.execute(query, context:)
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'returns an identifier derived from the session id' do
        expect(gql.result.data[:id]).to eq(OpenSSL::HMAC.hexdigest('SHA256', Setting.get('application_secret'), session.id.public_id))
      end

      it 'does not return the session id itself' do
        expect(gql.result.data[:id]).not_to eq(session.id.public_id)
      end

      it 'returns after_auth data' do
        expect(gql.result.data[:afterAuth]).to eq({ 'type' => 'TwoFactorConfiguration', 'data' => {} })
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
