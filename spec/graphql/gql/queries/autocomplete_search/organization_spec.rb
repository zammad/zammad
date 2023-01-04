# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::Organization, authenticated_as: :agent, type: :graphql do

  context 'when searching for organizations' do
    let(:agent)         { create(:agent) }
    let(:organizations) { create_list(:organization, 3, note: 'AutocompleteSearch') }
    let(:query) do
      <<~QUERY
        query autocompleteSearchOrganization($input: AutocompleteSearchOrganizationInput!) {
          autocompleteSearchOrganization(input: $input) {
            value
            label
            labelPlaceholder
            heading
            headingPlaceholder
            disabled
            icon
          }
        }
      QUERY
    end
    let(:variables)    { { input: { query: query_string, limit: limit } } }
    let(:query_string) { organizations.last.note }
    let(:limit)        { nil }

    context 'without limit' do
      it 'finds all organizations' do
        gql.execute(query, variables: variables)
        expect(gql.result.data.length).to eq(organizations.length)
      end
    end

    context 'with limit' do
      let(:limit) { 1 }

      it 'respects the limit' do
        gql.execute(query, variables: variables)
        expect(gql.result.data.length).to eq(limit)
      end
    end

    context 'with exact search' do
      let(:first_organization_payload) do
        {
          'value'              => organizations.first.id.to_s,
          'label'              => organizations.first.name,
          'labelPlaceholder'   => nil,
          'heading'            => nil,
          'headingPlaceholder' => nil,
          'icon'               => nil,
          'disabled'           => nil,
        }
      end
      let(:query_string) { organizations.first.name }

      it 'has data' do
        gql.execute(query, variables: variables)
        expect(gql.result.data).to eq([first_organization_payload])
      end
    end

    context 'when sending an empty search string' do
      let(:query_string) { '   ' }

      it 'returns nothing' do
        gql.execute(query, variables: variables)
        expect(gql.result.data.length).to eq(0)
      end
    end

    context 'when customer is set' do
      let(:organizations) { create_list(:organization, 5, note: 'AutocompleteSearch') }
      let(:customer)      { create(:customer, organization: organizations[0], organizations: [organizations[1], organizations[2]]) }
      let(:variables)     { { input: { query: query_string, limit: limit, customerId: gql.id(customer) } } }
      let(:query_string)  { 'dummy' }

      context 'with primary organization' do
        before do
          organizations.first.update!(note: query_string)
        end

        let(:primary_organization_payload) do
          {
            'value'              => organizations.first.id.to_s,
            'label'              => organizations.first.name,
            'labelPlaceholder'   => nil,
            'heading'            => nil,
            'headingPlaceholder' => nil,
            'icon'               => nil,
            'disabled'           => nil,
          }
        end

        it 'finds the primary organization' do
          gql.execute(query, variables: variables)
          expect(gql.result.data).to eq([primary_organization_payload])
        end
      end

      context 'with secondary organization' do
        let(:secondary_organization) { organizations[1] }

        let(:secondary_organization_payload) do
          {
            'value'              => secondary_organization.id.to_s,
            'label'              => secondary_organization.name,
            'labelPlaceholder'   => nil,
            'heading'            => nil,
            'headingPlaceholder' => nil,
            'icon'               => nil,
            'disabled'           => nil,
          }
        end

        before do
          secondary_organization.update!(note: query_string)
        end

        it 'finds the secondary organization' do
          gql.execute(query, variables: variables)
          expect(gql.result.data).to eq([secondary_organization_payload])
        end
      end

      context 'with unassigned organization' do
        let(:unassigned_organization) { organizations[3] }

        before do
          unassigned_organization.update!(note: query_string)
        end

        it 'returns nothing' do
          gql.execute(query, variables: variables)
          expect(gql.result.data.length).to eq(0)
        end
      end
    end

    context 'when unauthenticated' do
      before do
        gql.execute(query, variables: variables)
      end

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
