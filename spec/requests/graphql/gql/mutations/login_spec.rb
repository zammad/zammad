# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Login, type: :request do

  context 'when logging on' do
    let(:agent_password) { 'some_test_password' }
    let(:agent) { create(:agent, password: agent_password) }
    let(:query) do
      File.read(Rails.root.join('app/frontend/apps/mobile/graphql/mutations/login.graphql'))
    end
    let(:password) { agent_password }
    let(:fingerprint) { Faker::Number.number(digits: 6).to_s }
    let(:variables) do
      {
        login:       agent.login,
        password:    password,
        fingerprint: fingerprint,
      }
    end
    let(:graphql_response) do
      post '/graphql', params: { query: query, variables: variables }, as: :json
      json_response
    end

    context 'with correct credentials' do
      it 'returns session data' do
        expect(graphql_response['data']['login']['sessionId']).to be_present
      end
    end

    context 'with wrong password' do
      let(:password) { 'wrong' }

      it 'fails' do
        expect(graphql_response['errors'][0]['message']).to eq('Wrong login or password combination.')
      end
    end

    context 'without fingerprint' do
      let(:fingerprint) { nil }

      it 'fails' do
        expect(graphql_response['errors'][0]['message']).to eq('Variable $fingerprint of type String! was provided invalid value')
      end
    end

  end
end
