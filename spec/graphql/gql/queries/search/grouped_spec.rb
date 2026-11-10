# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The per-model search itself is covered in spec/services/service/search_spec.rb and
#   spec/services/service/knowledge_base/search_spec.rb.
RSpec.describe Gql::Queries::Search::Grouped, type: :graphql do

  context 'when performing generic searches' do
    let(:ticket_group) { create(:group) }
    let(:organization) { create(:organization, name: search) }
    let(:agent)        { create(:agent, firstname: search, groups: [ticket_group]) }
    let!(:ticket)      { create_ticket }
    let(:search)       { SecureRandom.uuid }
    let(:query) do
      <<~QUERY
        query searchGrouped(
          $search: String
          $onlyIn: [EnumSearchableModels!]!
          $limit: Int
        ) {
          searchGrouped(
            search: $search
            onlyIn: $onlyIn
            limit: $limit
          ) {
            model
            totalCount
            items {
              ... on Ticket {
                __typename
                number
              }
              ... on User {
                __typename
                firstname
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
    let(:only_in)   { %w[Organization Ticket User] }
    let(:variables) { { search: search, onlyIn: only_in } }
    let(:es_setup) do
      Setting.set('es_url', nil)
    end

    def create_ticket
      create(:ticket, title: search, group: ticket_group, organization: organization).tap do |ticket|
        # Article required to find ticket via SQL
        create(:ticket_article, ticket: ticket)
      end
    end

    def group(model)
      gql.result.data.find { |entry| entry['model'] == model }
    end

    before do
      es_setup
      gql.execute(query, variables: variables)
    end

    shared_examples 'test grouped search query' do
      context 'with an agent', authenticated_as: :agent do
        it 'answers one group per model with its items, in model priority order' do
          expect(gql.result.data).to eq([
                                          { 'model' => 'Ticket', 'totalCount' => 1, 'items' => [{ '__typename' => 'Ticket', 'number' => ticket.number }] },
                                          { 'model' => 'User', 'totalCount' => 1, 'items' => [{ '__typename' => 'User', 'firstname' => search }] },
                                          { 'model' => 'Organization', 'totalCount' => 1, 'items' => [{ '__typename' => 'Organization', 'name' => search }] },
                                        ])
        end

        context 'with a limit below the number of hits' do
          let!(:ticket) { create_ticket.tap { create_ticket } }
          let(:variables) { { search: search, onlyIn: %w[Ticket Organization], limit: 1 } }

          it 'returns the window per model' do
            expect(group('Ticket')['items'].size).to eq(1)
          end

          # What the quick search group's "%s more" count rests on.
          it 'still reports the whole permitted total' do
            expect(group('Ticket')['totalCount']).to eq(2)
          end
        end

        context 'with a repeated model' do
          let(:only_in) { %w[Ticket Ticket] }

          it 'answers it once' do
            expect(gql.result.data.pluck('model')).to eq(%w[Ticket])
          end
        end
      end

      context 'with a customer', authenticated_as: :customer do
        let(:customer) { create(:customer, firstname: search, organization: organization) }

        it 'finds only what the customer may see and omits models the customer may not search' do
          expect(gql.result.data).to contain_exactly(
            { 'model' => 'Ticket', 'totalCount' => 0, 'items' => [] },
            { 'model' => 'Organization', 'totalCount' => 1, 'items' => [{ '__typename' => 'Organization', 'name' => search }] },
          )
        end
      end
    end

    context 'without search index' do
      include_examples 'test grouped search query'
    end

    context 'with search index', searchindex: true do
      let(:es_setup) do
        searchindex_model_reload([Ticket, User, Organization])
      end

      include_examples 'test grouped search query'
    end

    context 'with a negative limit', authenticated_as: :agent do
      let(:variables) { { search: search, onlyIn: only_in, limit: -1 } }

      it 'rejects the argument' do
        expect(gql.result.error_message).to include('limit must be greater than or equal to 0')
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  # Served through a different backend than every other model here - see
  #   Gql::Concerns::SearchesKnowledgeBaseAnswers.
  context 'when searching knowledge base answers' do
    include_context 'basic Knowledge Base'

    let(:query) do
      <<~QUERY
        query searchGrouped($search: String, $onlyIn: [EnumSearchableModels!]!, $limit: Int) {
          searchGrouped(search: $search, onlyIn: $onlyIn, limit: $limit) {
            model
            totalCount
            items {
              ... on KnowledgeBaseAnswerTranslation {
                __typename
                title
              }
            }
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

      it 'answers the hits as their own group' do
        expect(gql.result.data).to match([{
                                           'model'      => 'KnowledgeBase__Answer__Translation',
                                           'totalCount' => 2,
                                           'items'      => contain_exactly(
                                             { '__typename' => 'KnowledgeBaseAnswerTranslation', 'title' => 'Ocarina tuning' },
                                             { '__typename' => 'KnowledgeBaseAnswerTranslation', 'title' => 'Ocarina repair' },
                                           ),
                                         }])
      end

      context 'with a limit below the number of hits' do
        let(:variables) { { search: search, onlyIn: only_in, limit: 1 } }

        it 'returns the window but keeps the whole permitted total' do
          expect(gql.result.data.first).to include('totalCount' => 2, 'items' => have_attributes(size: 1))
        end
      end

      context 'with a model the generic backend serves alongside it' do
        let(:only_in) { %w[Ticket KnowledgeBase__Answer__Translation] }

        it 'answers both' do
          expect(gql.result.data.pluck('model')).to eq(%w[Ticket KnowledgeBase__Answer__Translation])
        end
      end

      # The other groups of the same request must survive an instance without a knowledge base.
      context 'without an active knowledge base' do
        let(:kb_setup) { knowledge_base.update!(active: false) }
        let(:only_in)  { %w[Ticket KnowledgeBase__Answer__Translation] }

        it 'omits the model rather than failing' do
          expect(gql.result.data.pluck('model')).to eq(%w[Ticket])
        end
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
