# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::PasswordCheck, type: :graphql do
  let(:user)     { create(:agent, password: 'lorem') }
  let(:password) { 'lorem' }

  let(:mutation) do
    <<~GQL
      mutation userCurrentPasswordCheck($password: String!) {
        userCurrentPasswordCheck(password: $password) {
          success
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:variables) { { password: } }

  before { gql.execute(mutation, variables: variables) }

  context 'when user is not authenticated' do
    it 'returns an error' do
      expect(gql.result.error).to include('message' => 'Authentication required')
    end
  end

  context 'when user is authenticated', authenticated_as: :user do
    context 'when password is correct' do
      it 'returns success' do
        expect(gql.result.data).to include('success' => be_truthy)
      end
    end

    context 'when password is not correct' do
      let(:password) { '' }

      it 'returns an error' do
        expect(gql.result.data['errors'])
          .to include(
            include('field' => 'password', 'message' => 'The provided password is incorrect.')
          )
      end
    end
  end
end
