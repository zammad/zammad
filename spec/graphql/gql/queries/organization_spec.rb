# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Organization, type: :graphql do
  context 'when fetching organization' do
    let(:user)         { create(:agent) }
    let(:organization) { create(:organization) }
    let(:variables)    { { organizationId: gql.id(organization) } }
    let(:query) do
      <<~QUERY
        query organization($organizationId: ID, $organizationInternalId: Int) {
          organization( organization: { organizationId: $organizationId, organizationInternalId: $organizationInternalId } ) {
            id
            name
            shared
            domain
            domainAssignment
            active
            note
            ticketsCount {
              open
              closed
            }
          }
        }
      QUERY
    end

    before do
      gql.execute(query, variables: variables)
    end

    context 'with authenticated session', authenticated_as: :user do
      context 'when querying by Id' do
        it 'has data' do
          expect(gql.result.data).to include('name' => organization.name, 'shared' => organization.shared)
        end
      end

      context 'when querying by internalId' do
        let(:variables) { { organizationInternalId: organization.id } }

        it 'has data' do
          expect(gql.result.data).to include('name' => organization.name, 'shared' => organization.shared)
        end
      end

      context 'without organization' do
        let(:organization) { create(:organization).tap(&:destroy) }

        it 'fetches no organization' do
          expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
        end
      end

      context 'without organization assignment - no permission' do
        let(:user) { create(:customer) }

        it 'returns an error' do
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        end
      end

      context 'with organization assignment - permission' do
        let(:user) { create(:customer, organization: organization) }

        it 'returns a record, but only limited data', :aggregate_failures do
          expect(gql.result.data).to include('name' => organization.name, 'shared' => nil)
        end

        context 'with assignment to another organization' do
          let(:user) { create(:customer, organization: create(:organization)) }

          it 'returns an error' do
            expect(gql.result.error_type).to eq(Exceptions::Forbidden)
          end
        end
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
