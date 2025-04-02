# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::SignupResend, type: :graphql do
  context 'when resending signup verification email' do
    let(:user) { create(:user, verified: false) }

    let(:query) do
      <<~QUERY
        mutation userSignupResend($email: String!) {
          userSignupResend(email: $email) {
            success
            errors {
              message
            }
          }
        }
      QUERY
    end

    let(:variables) do
      {
        email: user.email,
      }
    end

    context 'with disabled user signup' do
      before do
        Setting.set('user_create_account', false)
      end

      it 'raises an error' do
        gql.execute(query, variables: variables)
        expect(gql.result.error_message).to eq 'This feature is not enabled.'
      end
    end

    context 'with valid user email address' do
      it 'returns success' do
        gql.execute(query, variables: variables)
        expect(gql.result.data).to eq({ 'success' => true, 'errors' => nil })
      end
    end

    context 'with invalid user email address' do
      let(:variables) do
        {
          email: 'foobar@example.tld',
        }
      end

      it 'returns success' do
        gql.execute(query, variables: variables)
        expect(gql.result.data).to eq({ 'success' => true, 'errors' => nil })
      end
    end
  end
end
