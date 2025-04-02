# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::PasswordReset::Verify, type: :graphql do
  context 'when verifying reset password token' do
    let(:user)  { create(:user) }
    let(:token) { User.password_reset_new_token(user.login)[:token].token }

    let(:query) do
      <<~QUERY
        mutation userPasswordResetVerify($token: String!)  {
          userPasswordResetVerify(token: $token) {
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
        token: token
      }
    end

    before do
      disable_user_lost_password if defined?(disable_user_lost_password)
      gql.execute(query, variables: variables)
    end

    context 'with disabled lost password feature' do
      let(:disable_user_lost_password) do
        Setting.set('user_lost_password', false)
      end

      it 'raises an error' do
        expect(gql.result.error_message).to eq 'This feature is not enabled.'
      end
    end

    context 'with a valid token' do
      it 'verifies password reset token' do
        expect(gql.result.data).to eq({ 'success' => true, 'errors' => nil })
      end
    end

    context 'with an invalid token' do
      let(:token) { SecureRandom.urlsafe_base64(48) }

      it 'raises an error' do
        expect(gql.result.data).to eq({ 'success' => nil, 'errors' => [{ 'message' => 'The provided token is invalid.' }] })
      end
    end
  end
end
