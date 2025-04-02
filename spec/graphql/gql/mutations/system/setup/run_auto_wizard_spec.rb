# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::System::Setup::RunAutoWizard, :aggregate_failures, set_up: false, type: :request do
  context 'when running the auto wizard' do
    let(:query) do
      <<~QUERY
        mutation systemSetupRunAutoWizard($token: String) {
          systemSetupRunAutoWizard(token: $token) {
            session {
              id
              afterAuth {
                type
                data
              }
            }
            errors {
              message
              field
            }
          }
        }
      QUERY
    end

    let(:variables) { { token: } }
    let(:token)     { nil }
    let(:headers)   { { 'X-Browser-Fingerprint' => 'some-fingerprint' } }

    let(:graphql_response) do
      post '/graphql', params: { query: query, variables: variables }, headers: headers, as: :json
      json_response
    end

    context 'with auto wizard not enabled' do
      it 'fails with an error' do
        expect(graphql_response['data']['systemSetupRunAutoWizard']['errors'].first['message']).to eq('An unexpected error occurred during system setup.')
      end
    end

    context 'with auto wizard enabled' do
      before do
        FileUtils.cp(Rails.root.join('contrib/auto_wizard_example.json'), Rails.root.join('auto_wizard.json'))
      end

      after do
        FileUtils.rm(Rails.root.join('auto_wizard.json'), force: true)
      end

      context 'without the right token' do
        it 'fails with an error' do
          expect(graphql_response['data']['systemSetupRunAutoWizard']['errors'].first['message']).to eq('An unexpected error occurred during system setup.')
        end
      end

      context 'with the right token' do
        let(:token) { 'secret_token' }

        it 'runs the auto wizard' do
          expect(graphql_response['data']['systemSetupRunAutoWizard']).to include({ 'session' => include({ 'id' => a_kind_of(String) }), 'errors' => nil })
          expect(User.find_by(email: 'hans.atila@zammad.org')).to be_present
          expect(Setting.get('system_init_done')).to be true
        end
      end
    end
  end
end
