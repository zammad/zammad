# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::CurrentUser, type: :request do

  context 'when fetching user information' do
    let(:organization) { create(:organization) }
    let(:agent) { create(:agent, department: 'TestDepartment', organization: organization) }
    let(:query) do
      File.read(Rails.root.join('app/frontend/apps/mobile/graphql/queries/currentUser.graphql')) +
        File.read(Rails.root.join('app/frontend/apps/mobile/graphql/fragments/objectAttributeValues.graphql'))
    end
    let(:graphql_response) do
      post '/graphql', params: { query: query }, as: :json
      json_response
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'has data' do
        expect(graphql_response['data']['currentUser']['firstname']).to eq(agent.firstname)
      end

      it 'has objectAttributeValue data for User' do
        oas = graphql_response['data']['currentUser']['objectAttributeValues']
        expect(oas.find { |oa| oa['attribute']['name'].eql?('department') }['value']).to eq('TestDepartment')
      end

      it 'has data for Organization' do
        expect(graphql_response['data']['currentUser']['organization']['name']).to eq(organization.name)
      end
    end

    context 'without authenticated session', authenticated_as: false do
      it 'fails with error message' do
        expect(graphql_response['errors'][0]['message']).to eq('Authentication required by Gql::Queries::CurrentUser')
      end

      it 'fails with error type' do
        expect(graphql_response['errors'][0]['extensions']).to include({ 'type' => 'Exceptions::NotAuthorized' })
      end

    end
  end
end
