# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::CurrentUser, type: :graphql do

  context 'when fetching user information' do
    let(:organization)   { create(:organization) }
    let(:secondary_orgs) { create_list(:organization, 2) }
    let(:agent)          { create(:agent, department: 'TestDepartment', organization: organization, organizations: secondary_orgs) }
    let(:query) do
      <<~QUERY
        query currentUser {
          currentUser {
            id
            firstname
            lastname
            fullname
            objectAttributeValues {
              attribute {
                name
              }
              value
            }
            organization {
              name
            }
            secondaryOrganizations {
              edges {
                node {
                  name
                }
              }
            }
            permissions {
              names
            }
            createdBy {
              firstname
            }
            updatedBy {
              firstname
            }
          }
        }
      QUERY
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

      it 'has data for primary and secondary organizations', :aggregate_failures do
        expect(gql.result.data['organization']).to include('name' => organization.name)
        expect(gql.result.nodes('secondaryOrganizations')).to eq(secondary_orgs.map { |o| { 'name' => o.name } })
      end

      it 'has permission data' do
        expect(gql.result.data['permissions']['names']).to eq(agent.permissions_with_child_names)
      end

      it 'has updatedBy data' do
        expect(gql.result.data['updatedBy']['firstname']).to eq(User.first.firstname)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'

  end
end
