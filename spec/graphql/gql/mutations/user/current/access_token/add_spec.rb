# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::AccessToken::Add, type: :graphql do
  let(:user)       { create(:agent) }
  let(:permission) { %w[ticket.agent] }
  let(:expires_at) { nil }
  let(:name)       { Faker::Lorem.word }

  let(:mutation) do
    <<~GQL
      mutation userCurrentAccessTokenAdd($input: UserAccessTokenInput!) {
        userCurrentAccessTokenAdd(input: $input) {
          token {
            id
          }
          tokenValue
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:variables) { { input: { name:, permission:, expiresAt: expires_at&.iso8601 } } }

  def execute_graphql_query
    gql.execute(mutation, variables: variables)
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      expect(execute_graphql_query.error_message).to eq('Authentication required')
    end
  end

  context 'when user is authenticated', authenticated_as: :user do
    context 'when user has insufficient permissions' do
      let(:user) { create(:customer) }

      it 'returns an error' do
        expect(execute_graphql_query.error_message)
          .to include("Failed Gql::EntryPoints::Mutations's authorization check")
      end
    end

    context 'with valid parameters' do
      it 'returns token and token value' do
        execute_graphql_query

        new_token = Token.last

        expect(gql.result.data)
          .to include(
            'token'      => include('id' => gql.id(new_token)),
            'tokenValue' => new_token.token,
          )
      end
    end

    context 'with expiration date' do
      let(:expires_at) { 1.day.from_now.to_date }

      it 'returns token with expiration date and token value' do
        execute_graphql_query

        expect(Token.last).to have_attributes(
          name:        name,
          preferences: include(permission: permission),
          expires_at:  expires_at
        )
      end
    end
  end
end
