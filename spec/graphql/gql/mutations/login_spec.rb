# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Login and logout work only via controller, so use type: request.
RSpec.describe Gql::Mutations::Login, type: :request do

  # Temporary Hack: skip tests if ENABLE_EXPERIMENTAL_MOBILE_FRONTEND is not set.
  # TODO: Remove when this switch is not needed any more.
  around do |example|
    example.run if ENV['ENABLE_EXPERIMENTAL_MOBILE_FRONTEND'] == 'true'
  end

  context 'when logging on' do
    let(:agent_password) { 'some_test_password' }
    let(:agent)          { create(:agent, password: agent_password) }
    let(:query) do
      <<~QUERY
        mutation login($input: LoginInput!) {
          login(input: $input) {
            sessionId
            errors {
              message
              field
            }
          }
        }
      QUERY
    end
    let(:password) { agent_password }
    let(:fingerprint) { Faker::Number.number(digits: 6).to_s }
    let(:variables) do
      {
        input: {
          login:       agent.login,
          password:    password,
          fingerprint: fingerprint,
        }
      }
    end

    let(:graphql_response) do
      execute_graphql_query
      json_response
    end

    def execute_graphql_query
      post '/graphql', params: { query: query, variables: variables }, as: :json
    end

    context 'with correct credentials' do
      it 'returns session data' do
        expect(graphql_response['data']['login']['sessionId']).to be_present
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
              login:       agent.login,
              password:    password,
              fingerprint: fingerprint,
              rememberMe:  remember_me,
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
        expect(graphql_response['data']['login']['errors']).to eq([{
                                                                    'message' => 'Login failed. Have you double-checked your credentials and completed the email verification step?',
                                                                    'field'   => nil
                                                                  }])
      end
    end

    context 'without fingerprint' do
      let(:fingerprint) { nil }

      it 'fails with error message' do
        expect(graphql_response['errors'][0]).to include('message' => 'Variable $input of type LoginInput! was provided invalid value for fingerprint (Expected value to not be null)')
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
