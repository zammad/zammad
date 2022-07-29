# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::CurrentUser, type: :graphql do

  context 'when fetching user information' do
    let(:organization) { create(:organization) }
    let(:agent)        { create(:agent, department: 'TestDepartment', organization: organization) }
    let(:query) do
      gql.read_files(
        'shared/graphql/queries/currentUser.graphql',
        'shared/graphql/fragments/currentUserAttributes.graphql',
        'shared/graphql/fragments/objectAttributeValues.graphql'
      )
    end

    before do
      gql.execute(query)
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'has data' do
        expect(gql.result.data).to include('fullname' => agent.fullname)
      end

      it 'has objectAttributeValue data for User' do
        oas = gql.result.data['objectAttributeValues']
        expect(oas.find { |oa| oa['attribute']['name'].eql?('department') }['value']).to eq('TestDepartment')
      end

      it 'has data for Organization' do
        expect(gql.result.data['organization']).to include('name' => organization.name)
      end

      it 'has permission data' do
        expect(gql.result.data['permissions']['names']).to eq(agent.permissions_with_child_names)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'

  end
end
