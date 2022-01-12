# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::CurrentUser, type: :graphql do

  context 'when fetching user information' do
    let(:organization) { create(:organization) }
    let(:agent) { create(:agent, department: 'TestDepartment', organization: organization) }
    let(:query) do
      read_graphql_file('common/graphql/queries/currentUser.graphql') +
        read_graphql_file('common/graphql/fragments/objectAttributeValues.graphql')
    end

    before do
      graphql_execute(query)
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'has data' do
        expect(graphql_response['data']['currentUser']).to include('firstname' => agent.firstname)
      end

      it 'has objectAttributeValue data for User' do
        oas = graphql_response['data']['currentUser']['objectAttributeValues']
        expect(oas.find { |oa| oa['attribute']['name'].eql?('department') }['value']).to eq('TestDepartment')
      end

      it 'has data for Organization' do
        expect(graphql_response['data']['currentUser']['organization']).to include('name' => organization.name)
      end

      it 'has permission data' do
        expect(graphql_response['data']['currentUser']['permissions']['names']).to eq(agent.permissions_with_child_names)
      end
    end

    include_examples 'graphql responds with error if unauthenticated'

  end
end
