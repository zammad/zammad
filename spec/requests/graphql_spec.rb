# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'GraphQL', type: :request do
  describe 'sensitive data is filtered out from logs' do
    let(:query) do
      <<~QUERY
        mutation testMutation() {
          test() {
          }
        }
      QUERY
    end

    let(:testing_string)     { 'visible test string' }
    let(:private_key_string) { 'private string to be redacted' }
    let(:password_string)    { 'testpassword' }
    let(:idp_cert_string)    { 'idp_cert_value' }

    let(:variables) do
      {
        testing:     testing_string,
        privateKey:  private_key_string,
        newPassword: password_string,
        idpCert:     idp_cert_string
      }
    end

    it 'does not log sensitive fields', aggregate_failures: true do
      allow(Rails.logger).to receive(:info)

      post '/graphql', params: { query: query, variables: variables }, as: :json

      expect(Rails.logger).to have_received(:info).with(%r{Parameters:}) do |message|
        expect(message)
          .to include(testing_string)
          .and(not_include(private_key_string))
          .and(not_include(password_string))
          .and(not_include(idp_cert_string))
      end
    end
  end

  describe 'custom errors for DDOS-like queries' do
    before do
      allow(Gql::ZammadSchema)
        .to receive(:execute)
        .and_raise(GraphqlValidations::Error, 'Abusive query detected')

      post '/graphql', params: { query: '{ abusiveQuery }' }, as: :json
    end

    it 'returns unprocessable content status' do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns JSON error for abusive queries' do
      expect(json_response).to eq(
        'errors' => [
          {
            'message' => 'Abusive query detected',
          }
        ]
      )
    end
  end
end
