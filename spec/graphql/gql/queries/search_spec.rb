# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Search, type: :graphql do

  context 'when performing generic searches' do
    let(:group)        { create(:group) }
    let(:organization) { create(:organization, name: search) }
    let(:agent)        { create(:agent, firstname: search, groups: [ticket.group]) }
    let!(:ticket)     do
      create(:ticket, title: search, organization: organization).tap do |ticket|
        # Article required to find ticket via SQL
        create(:ticket_article, ticket: ticket)
      end
    end
    let(:search)    { SecureRandom.uuid }
    let(:query)     do
      <<~QUERY
        query search($search: String!, $onlyIn: EnumSearchableModels!, $orderBy: String, $orderDirection: EnumOrderDirection, $offset: Int = 0, $limit: Int = 10) {
          search(search: $search, onlyIn: $onlyIn, orderBy: $orderBy, orderDirection: $orderDirection, offset: $offset, limit: $limit) {
            totalCount
            items {
              ... on Ticket {
                __typename
                number
                title
              }
              ... on User {
                __typename
                firstname
                lastname
              }
              ... on Organization {
                __typename
                name
              }
            }
          }
        }
      QUERY
    end
    let(:only_in)   { 'Ticket' }
    let(:order_by)  { 'title' }
    let(:variables) { { search: search, onlyIn: only_in, orderBy: order_by, orderDirection: 'ASCENDING' } }
    let(:es_setup) do
      Setting.set('es_url', nil)
    end

    before do
      es_setup
      gql.execute(query, variables: variables)
    end

    shared_examples 'test search query' do

      context 'with an agent', authenticated_as: :agent do
        let(:expected_result) do
          { 'items' => [{ '__typename' => 'Ticket', 'number' => ticket.number, 'title' => ticket.title }], 'totalCount' => 1 }
        end

        context 'with direct_search_index: false' do
          it 'finds expected objects' do
            expect(gql.result.data).to eq(expected_result)
          end
        end

        context 'with direct_search_index: true' do
          let(:only_in) { 'User' }
          let(:order_by) { 'login' }
          let(:expected_result) do
            { 'items' => [{ '__typename' => 'User', 'firstname' => agent.firstname, 'lastname' => agent.lastname }], 'totalCount' => 1 }
          end

          it 'finds expected objects' do
            expect(gql.result.data).to eq(expected_result)
          end
        end

        context 'with invalid order_by' do
          let(:order_by) { 'nonexisting' }

          it 'raises an error' do
            expect(gql.result.error_message).to eq("Found invalid column 'nonexisting' for sorting.")
          end
        end

        context 'with offset in a non-matching window' do
          let(:variables) { { search:, onlyIn: only_in, limit: 10, offset: 10 } }
          let(:expected_result) do
            { 'items' => [], 'totalCount' => 1 }
          end

          it 'finds expected objects across models' do
            expect(gql.result.data).to eq(expected_result)
          end
        end
      end

      context 'with a customer', authenticated_as: :customer do
        let(:customer) { create(:customer, firstname: search, organization: organization) }
        let(:only_in)  { 'Organization' }
        let(:order_by) { 'name' }
        let(:expected_result) do
          { 'items' => [{ '__typename' => 'Organization', 'name' => organization.name }], 'totalCount' => 1 }
        end

        it 'finds objects available to the customer' do
          expect(gql.result.data).to eq(expected_result)
        end

        context 'when searching for inacessible models' do
          let(:only_in) { 'User' }
          let(:order_by) { 'login' }
          let(:expected_result) do
            { 'items' => [], 'totalCount' => 0 }
          end

          it 'gets no result' do
            expect(gql.result.data).to eq(expected_result)
          end
        end
      end
    end

    context 'without search index' do
      include_examples 'test search query'
    end

    context 'with search index', searchindex: true do
      let(:es_setup) do
        searchindex_model_reload([Ticket, User, Organization])
      end

      include_examples 'test search query'
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
