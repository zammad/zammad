# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::PasswordReset::Send, type: :graphql do
  context 'when resetting a password for a user' do
    let(:user) { create(:user) }

    let(:query) do
      <<~QUERY
        mutation userPasswordResetSend($username: String!) {
          userPasswordResetSend(username: $username) {
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
        username: user.login
      }
    end

    context 'with disabled lost password feature' do
      before do
        Setting.set('user_lost_password', false)
      end

      it 'raises an error' do
        gql.execute(query, variables: variables)
        expect(gql.result.error_message).to eq 'This feature is not enabled.'
      end
    end

    context 'with import mode' do
      before do
        Setting.set('import_mode', true)
      end

      it 'raises an error' do
        gql.execute(query, variables: variables)

        expect(gql.result.data).to include(
          errors: include(
            include(message: 'The email could not be sent to the user because import_mode setting is on.')
          )
        )
      end
    end

    context 'with existing user' do
      it 'sends a password reset link', :aggregate_failures do
        message = nil

        allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
          message = params[:body]
        end

        expect { gql.execute(query, variables: variables) }.to change(Token, :count)
        expect(gql.result.data).to eq({ 'success' => true, 'errors' => nil })
        expect(message).to include("<a href=\"http://zammad.example.com/desktop/reset-password/verify/#{Token.last[:token]}\">")
      end
    end

    context 'with an invalid user' do
      let(:variables) do
        {
          username: 'foobar'
        }
      end

      it 'returns success, but does nothing', :aggregate_failures do
        expect { gql.execute(query, variables: variables) }.to not_change(Token, :count)
        expect(gql.result.data).to eq({ 'success' => true, 'errors' => nil })
      end
    end

    context 'when request is made more times than throttle allows', :rack_attack do
      let(:static_ipv4) { Faker::Internet.ip_v4_address }

      it 'blocks due to username throttling (multiple IPs)' do
        4.times do
          gql.execute(query, variables: variables, context: { REMOTE_IP: Faker::Internet.ip_v4_address })
        end

        expect(gql.result.error_message).to eq 'The request limit for this operation was exceeded.'
      end

      it 'blocks due to source IP address throttling (multiple usernames)' do
        4.times do
          gql.execute(query, variables: variables.merge(username: create(:user).login), context: { REMOTE_IP: static_ipv4 })
        end

        expect(gql.result.error_message).to eq 'The request limit for this operation was exceeded.'
      end
    end
  end
end
