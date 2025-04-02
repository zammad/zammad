# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::Generic, authenticated_as: :agent, type: :graphql do

  context 'when searching for users' do
    let(:agent)         { create(:agent, groups: [ticket.group]) }
    let!(:users)        { create_list(:customer, 3, lastname: 'AutocompleteSearch') }
    let!(:organization) { create(:organization, name: 'AutocompleteSearch') }
    let!(:ticket) do
      create(:ticket, title: 'AutocompleteSearch').tap do |ticket|
        # Article required to find ticket via SQL
        create(:ticket_article, ticket: ticket)
      end
    end

    let(:query) do
      <<~QUERY
        query autocompleteSearchGeneric($input: AutocompleteSearchGenericInput!)  {
          autocompleteSearchGeneric(input: $input) {
            value
            label
            object {
              ... on User { id }
              ... on Organization { id }
              ... on Ticket { id }
            }
          }
        }
      QUERY
    end
    let(:variables)    { { input: { query: query_string, limit:, onlyIn: only_in } } }
    let(:query_string) { 'AutocompleteSearch' }
    let(:limit)        { nil }
    let(:only_in)      { nil }

    before do
      gql.execute(query, variables: variables)
    end

    context 'without limit' do
      it 'finds all objects' do
        expect(gql.result.data.length).to eq(5)
      end
    end

    context 'with limit' do
      let(:limit) { 1 }
      let(:expected_data) do
        [
          {
            'label'  => "##{ticket.number} - #{ticket.title}",
            'value'  => ticket.id,
            'object' => { 'id' => gql.id(ticket) }
          },
          {
            'label'  => users.last.fullname,
            'value'  => users.last.id,
            'object' => { 'id' => gql.id(users.last) }
          },
          {
            'label'  => organization.name,
            'value'  => organization.id,
            'object' => { 'id' => gql.id(organization) }
          },
        ]
      end

      it 'respects the limit' do
        expect(gql.result.data).to eq(expected_data)
      end

      context 'with onlyIn' do
        let(:only_in) { ['Ticket'] }
        let(:expected_data) do
          [
            {
              'label'  => "##{ticket.number} - #{ticket.title}",
              'value'  => ticket.id,
              'object' => { 'id' => gql.id(ticket) }
            },
          ]
        end

        it 'filters objects' do
          expect(gql.result.data).to eq(expected_data)
        end
      end
    end

    context 'when sending an empty search string' do
      let(:query_string) { '   ' }

      it 'returns nothing' do
        expect(gql.result.data.length).to eq(0)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
