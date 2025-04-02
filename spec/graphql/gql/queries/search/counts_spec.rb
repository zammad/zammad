# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Search::Counts, type: :graphql do

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
        query searchCounts($search: String!, $onlyIn: [EnumSearchableModels!]!) {
          searchCounts(search: $search, onlyIn: $onlyIn) {
            model
            totalCount
          }
        }
      QUERY
    end
    let(:only_in)   { %w[Ticket Organization] }
    let(:variables) { { search: search, onlyIn: only_in } }
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
          [
            { 'model' => 'Ticket',       'totalCount' => 1 },
            { 'model' => 'Organization', 'totalCount' => 1 },
          ]
        end

        it 'finds expected objects across models' do
          expect(gql.result.data).to eq(expected_result)
        end
      end

      context 'with a customer', authenticated_as: :customer do
        let(:customer) { create(:customer, firstname: search, organization: organization) }
        let(:expected_result) do
          [
            { 'model' => 'Ticket',       'totalCount' => 0 },
            { 'model' => 'Organization', 'totalCount' => 1 },
          ]
        end

        it 'finds objects available to the customer' do
          expect(gql.result.data).to eq(expected_result)
        end

        context 'when searching for inacessible models' do
          let(:only_in) { 'User' }
          let(:expected_result) do
            []
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
