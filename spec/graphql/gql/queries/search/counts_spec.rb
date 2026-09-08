# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
        query searchCounts(
          $search: String
          $onlyIn: [EnumSearchableModels!]!
          $filters: [SelectorObjectInput!]
        ) {
          searchCounts(
            search: $search
            onlyIn: $onlyIn
            filters: $filters
          ) {
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

      context 'with an advanced filter and no search term', authenticated_as: :agent do
        let(:variables) do
          {
            onlyIn:  %w[Ticket],
            filters: [
              {
                object:   'Ticket',
                selector: {
                  operator:   'AND',
                  conditions: [
                    { name: 'ticket.title', operator: 'is', value: ticket.title },
                  ],
                },
              },
            ],
          }
        end

        let(:expected_result) do
          [
            { 'model' => 'Ticket', 'totalCount' => 1 },
          ]
        end

        it 'finds expected objects via the filter' do
          expect(gql.result.data).to eq(expected_result)
        end
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  # Counted through a different backend than every other model here - see
  #   Gql::Concerns::SearchesKnowledgeBaseAnswers. This is the path
  #   zammad/coordination-desktop-view#874's tab badge reads, so it has to work before that story
  #   starts.
  context 'when counting knowledge base answers' do
    include_context 'basic Knowledge Base'

    let(:query) do
      <<~QUERY
        query searchCounts($search: String, $onlyIn: [EnumSearchableModels!]!) {
          searchCounts(search: $search, onlyIn: $onlyIn) {
            model
            totalCount
          }
        }
      QUERY
    end

    let(:search)    { 'ocarina' }
    let(:only_in)   { ['KnowledgeBase__Answer__Translation'] }
    let(:variables) { { search: search, onlyIn: only_in } }
    let(:kb_setup)  { nil }

    let(:ocarina_published) do
      create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Ocarina tuning' })
    end

    let(:ocarina_internal) do
      create(:knowledge_base_answer, :internal, category: category, translation_attributes: { title: 'Ocarina repair' })
    end

    before do
      Setting.set('es_url', nil)
      ocarina_published
      ocarina_internal
      kb_setup
      gql.execute(query, variables: variables)
    end

    context 'with an agent (reader)', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      it 'counts the answers the user may see' do
        expect(gql.result.data).to eq([{ 'model' => 'KnowledgeBase__Answer__Translation', 'totalCount' => 2 }])
      end

      context 'with a model the generic backend serves alongside it' do
        let(:only_in) { %w[Ticket KnowledgeBase__Answer__Translation] }

        it 'reports both' do
          expect(gql.result.data).to include({ 'model' => 'KnowledgeBase__Answer__Translation', 'totalCount' => 2 })
        end
      end

      context 'without an active knowledge base' do
        let(:kb_setup) { knowledge_base.update!(active: false) }

        it 'omits the model rather than failing' do
          expect(gql.result.data).to eq([])
        end
      end
    end

    context 'with a customer (public)', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'counts published answers alone' do
        expect(gql.result.data).to eq([{ 'model' => 'KnowledgeBase__Answer__Translation', 'totalCount' => 1 }])
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
