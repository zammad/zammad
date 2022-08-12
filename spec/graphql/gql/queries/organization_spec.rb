# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Organization, type: :graphql do
  context 'when fetching organization' do
    let(:user)         { create(:agent) }
    let(:organization) { create(:organization) }
    let(:variables)    { { organizationId: gql.id(organization) } }
    let(:query) do
      gql.read_files(
        'apps/mobile/modules/organization/graphql/queries/organization.graphql',
        'apps/mobile/modules/organization/graphql/fragments/organizationAttributes.graphql',
        'shared/graphql/fragments/objectAttributeValues.graphql',
      )
    end

    before do
      gql.execute(query, variables: variables)
    end

    context 'with authenticated session', authenticated_as: :user do
      it 'has data' do
        expect(gql.result.data).to include('name' => organization.name)
      end

      context 'without organization' do
        let(:organization) { create(:organization).tap(&:destroy) }

        it 'fetches no organization' do
          expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
        end
      end

      context 'without organization assignment - no permission' do
        let(:user) { create(:customer) }

        it 'raises authorization error' do
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        end
      end

      context 'with organization assignment - permission' do
        let(:user) { create(:customer, organization: organization) }

        it 'has data' do
          expect(gql.result.data).to include('name' => organization.name)
        end

        context 'with assignment to another organization' do
          let(:user) { create(:customer, organization: create(:organization)) }

          it 'raises authorization error' do
            expect(gql.result.error_type).to eq(Exceptions::Forbidden)
          end
        end
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
