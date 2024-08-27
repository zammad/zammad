# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::AccessToken::Delete, type: :graphql do
  let(:user)     { create(:agent) }
  let(:token)    { create(:token, user:) }
  let(:token_id) { gql.id(token) }

  let(:mutation) do
    <<~GQL
      mutation userCurrentAccessTokenDelete($tokenId: ID!) {
        userCurrentAccessTokenDelete(tokenId: $tokenId) {
          success
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:variables) { { tokenId: token_id } }

  def execute_graphql_query
    gql.execute(mutation, variables: variables)
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      expect(execute_graphql_query.error_message).to eq('Authentication required')
    end

  end

  context 'when user is authenticated', authenticated_as: :user do
    context 'when token is given' do
      it 'deletes token' do
        expect { execute_graphql_query }
          .to change { Token.exists? token.id }
          .to false
      end

      it 'returns success' do
        execute_graphql_query

        expect(gql.result.data).to include('success' => true)
      end
    end

    context 'when nonexistant token is given' do
      let(:token_id) { Gql::ZammadSchema.id_from_internal_id(Token, 0) }

      it 'returns an error' do
        expect(execute_graphql_query.error_message).to include("Couldn't find Token ")
      end
    end

    context 'when given token is owned by another user' do
      let(:token) { create(:token) }

      it 'returns an error' do
        expect(execute_graphql_query.error_message).to eq('not allowed to TokenPolicy#destroy? this Token')
      end

      it 'does not delete token' do
        expect { execute_graphql_query }
          .not_to change { Token.exists? token.id }
          .from(true)
      end
    end

    context 'when given token is not persistent by another user' do
      let(:token) { create(:token, persistent: false, user: user) }

      it 'returns an error' do
        expect(execute_graphql_query.error_message).to eq('not allowed to TokenPolicy#destroy? this Token')
      end

      it 'does not delete token' do
        expect { execute_graphql_query }
          .not_to change { Token.exists? token.id }
          .from(true)
      end
    end
  end
end
