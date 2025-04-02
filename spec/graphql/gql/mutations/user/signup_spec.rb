# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Signup, type: :graphql do
  context 'when registering a new user' do
    let(:query) do
      <<~QUERY
        mutation userSignup($input: UserSignupInput!) {
          userSignup(input: $input) {
            success
            errors {
              message
              field
            }
          }
        }
      QUERY
    end

    let(:variables) do
      {
        input: {
          email:     'bender@futurama.fiction',
          firstname: 'Bender',
          lastname:  'Rodríguez',
          password:  'IloveBender1337'
        }
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

    context 'with enabled user signup' do
      before do
        Setting.set('user_create_account', true)
      end

      it 'creates a new user', :aggregate_failures do
        message = nil

        allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
          message = params[:body]
        end

        gql.execute(query, variables: variables)
        expect(gql.result.data).to eq({ 'success' => true, 'errors' => nil })
        expect(User.find_by(email: 'bender@futurama.fiction')).to be_present
        expect(message).to include("<a href=\"http://zammad.example.com/desktop/signup/verify/#{Token.last[:token]}\">")
      end

      context 'when the password is weak' do
        let(:variables) do
          {
            input: {
              email:     'bender@futurama.fiction',
              firstname: 'Bender',
              lastname:  'Rodríguez',
              password:  'idonotlovebenderandthisiswrong'
            }
          }
        end

        it 'raises an error', :aggregate_failures do
          gql.execute(query, variables: variables)

          errors = gql.result.data[:errors].first
          expect(errors.keys).to include('message', 'field')
          expect(errors['message']).to include('Invalid password')
          expect(errors['field']).to eq('password')
        end
      end

      context 'when the email is already taken' do
        before do
          create(:user, email: 'bender@futurama.fiction')
        end

        it 'returns a silent success', :aggregate_failures do
          message = nil
          allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
            message = params[:body]
          end
          gql.execute(query, variables: variables)

          expect(gql.result.data).to eq({ 'success' => true, 'errors' => nil })
          expect(message).to include('You or someone else tried to sign up with this email address.')
          expect(message).to include("<a href=\"http://zammad.example.com/desktop/reset-password/verify/#{Token.last[:token]}\">")
        end
      end

      context 'when the request is made more times than throttle allows', :rack_attack do
        let(:static_ipv4) { Faker::Internet.unique.ip_v4_address }

        it 'blocks due to email address throttling (multiple IPs)' do
          4.times do
            gql.execute(query, variables: variables, context: { REMOTE_IP: Faker::Internet.unique.ip_v4_address })
          end

          expect(gql.result.error_message).to eq 'The request limit for this operation was exceeded.'
        end

        it 'blocks due to source IP address throttling (multiple email addresses)' do
          new_variables = {
            input: {
              email:     Faker::Internet.unique.email,
              firstname: 'Bender',
              lastname:  'Rodríguez',
              password:  'IloveBender1337'
            }
          }

          4.times do
            gql.execute(query, variables: new_variables, context: { REMOTE_IP: static_ipv4 })
          end

          expect(gql.result.error_message).to eq 'The request limit for this operation was exceeded.'
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
              include(message: 'Could not create user and send verification email because import_mode setting is on.')
            )
          )
        end
      end
    end
  end
end
