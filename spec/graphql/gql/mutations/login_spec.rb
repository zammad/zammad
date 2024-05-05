# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Login and logout work only via controller, so use type: request.
RSpec.describe Gql::Mutations::Login, :aggregate_failures, type: :request do

  before do
    stub_const('Auth::BRUTE_FORCE_SLEEP', 0)
  end

  context 'when logging on' do
    let(:agent_password) { 'some_test_password' }
    let(:agent)          { create(:agent, password: agent_password) }
    let(:query) do
      <<~QUERY
        mutation login($input: LoginInput!) {
          login(input: $input) {
            session {
              id
              afterAuth {
                type
                data
              }
            }
            twoFactorRequired {
              defaultTwoFactorAuthenticationMethod
              availableTwoFactorAuthenticationMethods
              recoveryCodesAvailable
            }
            errors {
              message
              field
            }
          }
        }
      QUERY
    end
    let(:password) { agent_password }
    let(:fingerprint)               { Faker::Number.unique.number(digits: 6).to_s }
    let(:two_factor_authentication) { nil }
    let(:two_factor_recovery)       { nil }
    let(:variables) do
      {
        input: {
          login:                   agent.login,
          password:                password,
          twoFactorAuthentication: two_factor_authentication,
          twoFactorRecovery:       two_factor_recovery
        }
      }
    end
    let(:headers) do
      {
        'X-Browser-Fingerprint' => fingerprint,
      }
    end

    let(:graphql_response) do
      execute_graphql_query
      json_response
    end

    def execute_graphql_query
      post '/graphql', params: { query: query, variables: variables }, headers: headers, as: :json
    end

    context 'with correct credentials' do
      context 'without two factor authentication' do
        it 'returns session data' do
          expect(graphql_response['data']['login']['session']['id']).to be_present
        end

        it 'sets the :persistent session parameter' do
          expect { execute_graphql_query }.to change { request&.session&.fetch(:persistent) }.to(true)
        end

        it 'adds an activity stream entry for the user’s session' do
          # Create the user before the GraphQL query execution, so that we have only the activity stream
          # change from the login.
          agent

          expect { execute_graphql_query }.to change(ActivityStream, :count).by(1)
        end

        context 'with remember me' do
          let(:remember_me) { true }
          let(:variables) do
            {
              input: {
                login:      agent.login,
                password:   password,
                rememberMe: remember_me,
              }
            }
          end

          it 'adds an activity stream entry for the user’s session' do
            execute_graphql_query
            expect(request.env['rack.session.options'][:expire_after]).to eq(1.year)
          end

          context 'with not activated remember me' do
            let(:remember_me) { false }

            it 'adds an activity stream entry for the user’s session' do
              execute_graphql_query
              expect(request.env['rack.session.options'][:expire_after]).to be_nil
            end
          end
        end
      end

      context 'with after_auth information' do
        before do
          allow_any_instance_of(Auth::AfterAuth::TwoFactorConfiguration).to receive(:check).and_return(true)
        end

        it 'returns after_auth data' do
          expect(graphql_response['data']['login']['session']['afterAuth']).to eq({ 'type' => 'TwoFactorConfiguration', 'data' => {} })
        end
      end

      context 'with two factor authentication' do
        let!(:two_factor_pref) { create(:user_two_factor_preference, :authenticator_app, user: agent) }
        let(:enabled)          { true }

        before do
          Setting.set('two_factor_authentication_method_authenticator_app', enabled)
        end

        context 'without token' do
          it 'returns two factor availability data' do
            expect(graphql_response['data']['login']['twoFactorRequired']).to eq(
              {
                'defaultTwoFactorAuthenticationMethod'    => 'authenticator_app',
                'availableTwoFactorAuthenticationMethods' => ['authenticator_app'],
                'recoveryCodesAvailable'                  => false
              }
            )
            expect(graphql_response['data']['login']['session']).not_to be_present
          end
        end

        context 'with wrong token' do
          let(:two_factor_authentication) do
            {
              twoFactorMethod:  :authenticator_app,
              twoFactorPayload: 'wrong'
            }
          end

          it 'fails with error message' do
            expect(graphql_response['data']['login']['errors']).to eq(
              [{
                'message' => 'Login failed. Please double-check your two-factor authentication method.',
                'field'   => nil
              }]
            )
          end

          context 'when default method is disabled, but another exists' do
            let(:enabled) { true }

            before do
              two_factor_pref

              create(:user_two_factor_preference, :security_keys, user: agent)

              agent.reload
              agent.preferences[:two_factor_authentication][:default] = 'security_keys'
              agent.save!
            end

            it 'fails with error message' do
              expect(graphql_response['data']['login']['errors']).to eq(
                [{
                  'message' => 'Login failed. Please double-check your two-factor authentication method.',
                  'field'   => nil
                }]
              )
            end
          end

          context 'with disabled authenticator method' do
            let(:enabled) { false }

            it 'returns session data' do
              expect(graphql_response['data']['login']['session']['id']).to be_present
            end
          end
        end

        context 'with correct token' do
          let(:two_factor_authentication) do
            {
              twoFactorMethod:  :authenticator_app,
              twoFactorPayload: two_factor_pref.configuration[:code]
            }
          end

          it 'returns session data' do
            expect(graphql_response['data']['login']['session']['id']).to be_present
          end

          context 'with disabled authenticator method' do
            let(:enabled) { false }

            it 'returns session data' do
              expect(graphql_response['data']['login']['session']['id']).to be_present
            end
          end
        end

      end
    end

    context 'without CSRF token', allow_forgery_protection: true do
      it 'fails with error message' do
        expect(graphql_response['errors'][0]).to include('message' => 'CSRF token verification failed!')
      end

      it 'fails with error type' do
        expect(graphql_response['errors'][0]['extensions']).to include({ 'type' => 'Exceptions::NotAuthorized' })
      end
    end

    context 'with wrong password' do
      let(:password) { 'wrong' }

      it 'fails with error message' do
        expect(graphql_response['data']['login']['errors']).to eq(
          [{
            'message' => 'Login failed. Have you double-checked your credentials and completed the email verification step?',
            'field'   => nil
          }]
        )
      end
    end

    context 'without fingerprint' do
      let(:fingerprint) { nil }

      it 'fails with error message' do
        expect(graphql_response['errors'][0]).to include('message' => 'Need fingerprint param!')
      end

      # No error type available for GraphQL::ExecutionErrors.
    end

    context 'with fingerprint' do
      let(:fingerprint) { 'my_finger_print' }

      it 'exists in controller session' do
        execute_graphql_query

        expect(controller.session[:user_device_fingerprint]).to eq('my_finger_print')
      end

      it 'added user device log entry', :performs_jobs do
        perform_enqueued_jobs only: UserDeviceLogJob do
          execute_graphql_query
        end

        expect(UserDevice.where(user_id: agent.id).count).to eq(1)
      end
    end
  end
end
