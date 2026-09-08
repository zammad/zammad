# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Search, type: :graphql do

  context 'when performing generic searches' do
    let(:group)        { create(:group) }
    let(:organization) { create(:organization, name: search) }
    let(:agent)        { create(:agent, firstname: search, groups: [ticket.group]) }
    let(:tag1)         { Faker::Lorem.unique.word }
    let(:tag2)         { Faker::Lorem.unique.word }
    let!(:ticket)     do
      create(:ticket, title: search, organization: organization).tap do |ticket|
        # Article required to find ticket via SQL
        create(:ticket_article, ticket: ticket)

        ticket.tag_add(tag1, 1)
        ticket.tag_add(tag2, 1)
      end
    end
    let(:search)    { SecureRandom.uuid }
    let(:query)     do
      <<~QUERY
        query search(
          $search: String
          $onlyIn: EnumSearchableModels!
          $filter: SelectorNodeInput
          $orderBy: String
          $orderDirection: EnumOrderDirection
          $offset: Int = 0
          $limit: Int = 10
        ) {
          search(
            search: $search
            onlyIn: $onlyIn
            filter: $filter
            orderBy: $orderBy
            orderDirection: $orderDirection
            offset: $offset
            limit: $limit
          ) {
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
            expect(gql.result.error_message).to eq(__("Found invalid column 'nonexisting' for sorting."))
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

      context 'with an advanced tags filter', authenticated_as: :agent do
        let(:variables) do
          {
            onlyIn: 'Ticket',
            filter: {
              operator:   'AND',
              conditions: [
                { name: 'ticket.tags', operator: 'contains one', value: [tag1, tag2] },
              ],
            },
          }
        end

        let(:expected_result) do
          { 'items' => [{ '__typename' => 'Ticket', 'number' => ticket.number, 'title' => ticket.title }], 'totalCount' => 1 }
        end

        it 'finds expected objects via the filter' do
          expect(gql.result.data).to eq(expected_result)
        end
      end

      context 'with a scalar (non-array) tags filter value', authenticated_as: :agent do
        # The array-to-string transform only runs for array values; a scalar
        # value must pass through untouched instead of raising on `.join`.
        let(:variables) do
          {
            onlyIn: 'Ticket',
            filter: {
              operator:   'AND',
              conditions: [
                { name: 'ticket.tags', operator: 'contains one', value: tag1 },
              ],
            },
          }
        end

        let(:expected_result) do
          { 'items' => [{ '__typename' => 'Ticket', 'number' => ticket.number, 'title' => ticket.title }], 'totalCount' => 1 }
        end

        it 'finds expected objects without raising' do
          expect(gql.result.data).to eq(expected_result)
        end
      end
    end

    context 'with search index', searchindex: true do
      let(:es_setup) do
        searchindex_model_reload([Ticket, User, Organization])
      end

      include_examples 'test search query'

      context 'with an advanced filter and no search term', authenticated_as: :agent do
        let(:variables) do
          {
            onlyIn: 'Ticket',
            filter: {
              operator:   'AND',
              conditions: [
                { name: 'ticket.title', operator: 'is', value: ticket.title },
              ],
            },
          }
        end

        let(:expected_result) do
          { 'items' => [{ '__typename' => 'Ticket', 'number' => ticket.number, 'title' => ticket.title }], 'totalCount' => 1 }
        end

        it 'finds expected objects via the filter' do
          expect(gql.result.data).to eq(expected_result)
        end
      end

      context 'with a deeply nested advanced filter', authenticated_as: :agent do
        let(:variables) do
          {
            onlyIn: 'Ticket',
            filter: deep_nested_filter,
          }
        end

        let(:deep_nested_filter) do
          filter = {
            operator:   'AND',
            conditions: [{ name: 'ticket.title', operator: 'is', value: ticket.title }],
          }

          3.times do
            filter = {
              operator:   'AND',
              conditions: [filter],
            }
          end

          filter
        end

        it 'rejects the filter' do
          expect(gql.result.error_message).to eq('Selector exceeded maximum nesting depth.')
        end
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  # The one searchable model this query does not serve through Service::Search - see
  #   Gql::Concerns::SearchesKnowledgeBaseAnswers for why. What is covered here is the routing and
  #   the payload it produces; the search mode behind it belongs to Service::KnowledgeBase::Search
  #   and is covered in spec/services/service/knowledge_base/search_spec.rb.
  context 'when searching knowledge base answers' do
    include_context 'basic Knowledge Base'

    let(:query) do
      <<~QUERY
        query search($search: String, $onlyIn: EnumSearchableModels!, $limit: Int = 10, $offset: Int = 0) {
          search(search: $search, onlyIn: $onlyIn, limit: $limit, offset: $offset) {
            totalCount
            items {
              ... on KnowledgeBaseAnswerTranslation {
                __typename
                title
                visibility
                answer {
                  id
                }
              }
            }
          }
        }
      QUERY
    end

    let(:search)     { 'ocarina' }
    let(:variables)  { { search: search, onlyIn: 'KnowledgeBase__Answer__Translation' } }
    let(:es_setup)   { Setting.set('es_url', nil) }
    let(:kb_setup)   { nil }

    let(:ocarina_published) do
      create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Ocarina tuning' })
    end

    let(:ocarina_internal) do
      create(:knowledge_base_answer, :internal, category: category, translation_attributes: { title: 'Ocarina repair' })
    end

    def titles
      gql.result.data['items'].pluck('title')
    end

    before do
      es_setup
      ocarina_published
      ocarina_internal
      kb_setup
      gql.execute(query, variables: variables)
    end

    context 'with an agent (reader)', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      # The searchable unit is the translation, so the union member is the translation type - which
      #   is what the quicksearch group renders and what its popover is keyed on.
      it 'returns the hits as answer translations' do
        expect(gql.result.data['items']).to all(include('__typename' => 'KnowledgeBaseAnswerTranslation'))
      end

      it 'resolves the answer behind each translation' do
        expect(gql.result.data['items']).to all(include('answer' => include('id')))
      end

      it 'reports a total count next to the items' do
        expect(gql.result.data['totalCount']).to eq(2)
      end

      it 'includes internal answers' do
        expect(titles).to include('Ocarina repair')
      end

      context 'with a term nothing matches' do
        let(:search) { 'sackbut' }

        it 'reports an empty result' do
          expect(gql.result.data).to eq({ 'items' => [], 'totalCount' => 0 })
        end
      end

      # The one thing this resolver does that the service does not, and what the quicksearch group's
      #   "%s more" count and the story's AC9/AC10 rest on: `items` is the requested window while
      #   `totalCount` stays the whole permitted set.
      context 'with a limit below the number of hits' do
        let(:variables) { { search: search, onlyIn: 'KnowledgeBase__Answer__Translation', limit: 1 } }

        it 'returns the window' do
          expect(gql.result.data['items'].size).to eq(1)
        end

        it 'still reports the whole permitted total' do
          expect(gql.result.data['totalCount']).to eq(2)
        end
      end

      context 'with an offset past the end' do
        let(:variables) { { search: search, onlyIn: 'KnowledgeBase__Answer__Translation', limit: 10, offset: 10 } }

        it 'returns no items but keeps the total' do
          expect(gql.result.data).to eq({ 'items' => [], 'totalCount' => 2 })
        end
      end

      # Quicksearch asks for every searchable entity in one document, so this branch must answer
      #   rather than raise - raising would take the ticket, user and organization groups down with
      #   it on every instance that has no knowledge base.
      context 'without an active knowledge base' do
        let(:kb_setup) { knowledge_base.update!(active: false) }

        it 'reports an empty result instead of an error' do
          expect(gql.result.data).to eq({ 'items' => [], 'totalCount' => 0 })
        end
      end
    end

    context 'with a customer (public)', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'returns published answers' do
        expect(titles).to include('Ocarina tuning')
      end

      it 'hides internal answers' do
        expect(titles).not_to include('Ocarina repair')
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
