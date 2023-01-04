# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
        query search($search: String!, $onlyIn: EnumSearchableModels) {
          search(search: $search, onlyIn: $onlyIn) {
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
      QUERY
    end
    let(:variables) { { search: search } }
    let(:es_setup) do
      Setting.set('es_url', nil)
    end

    before do
      es_setup
      gql.execute(query, variables: variables)
    end

    shared_examples 'test search query' do

      context 'with an agent', authenticated_as: :agent do
        context 'without model limit' do
          let(:expected_result) do
            [
              { '__typename' => 'Ticket', 'number' => ticket.number, 'title' => ticket.title },
              { '__typename' => 'User', 'firstname' => agent.firstname, 'lastname' => agent.lastname },
              { '__typename' => 'Organization', 'name' => organization.name },
            ]
          end

          it 'finds expected objects across models' do
            expect(gql.result.data).to eq(expected_result)
          end
        end

        context 'with model restriction' do
          let(:variables) { { search: search, onlyIn: 'User' } }
          let(:expected_result) do
            [
              { '__typename' => 'User', 'firstname' => agent.firstname, 'lastname' => agent.lastname },
            ]
          end

          it 'finds expected objects only from selected model' do
            expect(gql.result.data).to eq(expected_result)
          end
        end
      end

      context 'with a customer', authenticated_as: :customer do
        let(:customer) { create(:customer, firstname: search, organization: organization) }
        let(:expected_result) do
          [
            { '__typename' => 'Organization', 'name' => organization.name },
          ]
        end

        it 'finds only objects available to the customer' do
          expect(gql.result.data).to eq(expected_result)
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
