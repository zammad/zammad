# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
end
