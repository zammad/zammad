# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::AdminPasswordAuthSend, type: :graphql do
  context 'when sending admin password auth' do
    let(:query) do
      <<~QUERY
        mutation adminPasswordAuthSend($login: String!) {
          adminPasswordAuthSend(login: $login) {
            success
          }
        }
      QUERY
    end

    let(:variables) do
      { login: login }
    end

    context 'with enabled password login' do
      let(:login) { 'john.doe' }

      before do
        Setting.set('user_show_password_login', true)
      end

      it 'raises an error' do
        gql.execute(query, variables: variables)
        expect(gql.result.error_message).to eq 'This feature is not enabled.'
      end
    end

    context 'with disabled password login' do
      let(:login) { 'john.doe' }

      context 'when no third-party authenticator is enabled' do
        before do
          Setting.set('user_show_password_login', false)
        end

        it 'raises an error' do
          gql.execute(query, variables: variables)
          expect(gql.result.error_message).to eq 'This feature is not enabled.'
        end
      end

      context 'when any third-party authenticator is enabled' do
        before do
          Setting.set('user_show_password_login', false)
          Setting.set('auth_saml', true)
        end

        let(:login) { create(:admin).login }

        it 'sends a valid login link' do
          message = nil

          allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
            message = params[:body]
          end

          gql.execute(query, variables: variables)

          expect(message).to include "<a href=\"http://zammad.example.com/desktop/login?token=#{Token.last.token}\">"
        end

        context 'when user requests admin auth more than throttle allows', :rack_attack do

          let(:static_ipv4) { Faker::Internet.ip_v4_address }

          it 'blocks due to username throttling (multiple IPs)' do
            4.times do
              gql.execute(query, variables: variables, context: { REMOTE_IP: Faker::Internet.ip_v4_address })
            end

            expect(gql.result.error_message).to eq 'The request limit for this operation was exceeded.'
          end

          it 'blocks due to source IP address throttling (multiple usernames)' do
            4.times do
              gql.execute(query, variables: variables.merge(username: create(:admin).login), context: { REMOTE_IP: static_ipv4 })
            end

            expect(gql.result.error_message).to eq 'The request limit for this operation was exceeded.'
          end
        end
      end
    end
  end
end
