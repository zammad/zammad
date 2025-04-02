# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Tickets::Cached::ByOverview, :aggregate_failures, type: :graphql do

  context 'when fetching cached ticket overviews' do
    let(:agent)     { create(:agent) }
    let(:query)     do
      <<~QUERY
        query ticketsCachedByOverview(
          $overviewId: ID!
          $orderBy: String
          $orderDirection: EnumOrderDirection
          $cursor: String
          $pageSize: Int
          $knownCollectionSignature: String
          $cacheTtl: Int!
          $renewCache: Boolean
        ) {
          ticketsCachedByOverview(
            overviewId: $overviewId
            orderBy: $orderBy
            orderDirection: $orderDirection
            after: $cursor
            first: $pageSize
            knownCollectionSignature: $knownCollectionSignature
            cacheTtl: $cacheTtl
            renewCache: $renewCache
          ) {
            totalCount
            collectionSignature
            edges {
              node {
                id
                internalId
                number
                articleCount
                stateColorCode
                escalationAt
                firstResponseEscalationAt
                updateEscalationAt
                closeEscalationAt
                firstResponseAt
                closeAt
                timeUnit
                lastCloseAt
                lastContactAt
                lastContactAgentAt
                lastContactCustomerAt
                policy {
                  update
                  agentReadAccess
                }
              }
            }
          }
        }
      QUERY
    end

    let(:known_collection_signature) { nil }
    let(:cache_ttl)      { 4.seconds }
    # make sure that we can display many tickets with our query
    let(:page_size)      { 1000 } # this would trigger an error without the custom complexity calculation
    let(:variables)      { { pageSize: page_size, overviewId: gql.id(overview), knownCollectionSignature: known_collection_signature, cacheTtl: cache_ttl } }
    let(:overview)       { Overview.find_by(link: 'all_unassigned') }
    let!(:ticket)        { create(:ticket) }

    context 'with an agent', authenticated_as: :agent do
      def trace_queries(queries, &block)
        callback = lambda do |*, payload|
          queries[payload[:name]] ||= 0
          queries[payload[:name]] += 1
        end
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
        queries
      end

      def ensure_no_ticket_queries(&block)
        queries = trace_queries({}, &block)
        expect(queries).not_to have_key('Ticket Load')
        expect(queries).not_to have_key('Ticket Count')
      end

      def ensure_ticket_queries(&block)
        queries = trace_queries({}, &block)
        expect(queries).to have_key('Ticket Load')
        expect(queries).to have_key('Ticket Count')
      end

      def ensure_fragment_writes
        allow(GraphQL::FragmentCache.cache_store).to receive(:write_multi).and_call_original
        yield
        expect(GraphQL::FragmentCache.cache_store).to have_received(:write_multi)
      end

      def ensure_no_fragment_writes
        allow(GraphQL::FragmentCache.cache_store).to receive(:write_multi).and_call_original
        yield
        expect(GraphQL::FragmentCache.cache_store).not_to have_received(:write_multi)
      end

      let(:agent) { create(:agent, groups: [ticket.group]) }

      context 'with an overview with complex conditions' do
        let(:overview) { create(:overview, :condition_expert) }

        it 'creates a cache on first call' do
          ensure_fragment_writes do
            ensure_ticket_queries do
              gql.execute(query, variables:)
            end
          end
          expect(gql.result.nodes.first).to include('number' => ticket.number)
          expect(gql.result.data).to include('totalCount' => 1, 'collectionSignature' => be_present)
        end
      end

      it 'creates a cache on first call' do
        ensure_fragment_writes do
          ensure_ticket_queries do
            gql.execute(query, variables:)
          end
        end
        expect(gql.result.nodes.first).to include('number' => ticket.number)
        expect(gql.result.data).to include('totalCount' => 1, 'collectionSignature' => be_present)
      end

      it 'uses a cache on second call' do
        gql.execute(query, variables:)

        ensure_no_fragment_writes do
          ensure_no_ticket_queries do
            gql.execute(query, variables:)
          end
        end
        expect(gql.result.nodes.first).to include('number' => ticket.number)
        expect(gql.result.data).to include('totalCount' => 1, 'collectionSignature' => be_present)
      end

      it 'recreates the cache on second call if renewCache is provided' do
        gql.execute(query, variables:)

        ensure_fragment_writes do
          ensure_ticket_queries do
            gql.execute(query, variables: variables.merge({ renewCache: true }))
          end
        end
        expect(gql.result.nodes.first).to include('number' => ticket.number)
        expect(gql.result.data).to include('totalCount' => 1, 'collectionSignature' => be_present)
      end

      it 'does not include renewCache in the cache key' do
        gql.execute(query, variables: variables.merge({ renewCache: true }))

        ensure_no_fragment_writes do
          ensure_no_ticket_queries do
            gql.execute(query, variables:)
          end
        end
        expect(gql.result.nodes.first).to include('number' => ticket.number)
        expect(gql.result.data).to include('totalCount' => 1, 'collectionSignature' => be_present)
      end

      it 'recreates the cache on second call if cache has expired' do
        freeze_time
        gql.execute(query, variables:)
        travel(cache_ttl)

        ensure_fragment_writes do
          ensure_ticket_queries do
            gql.execute(query, variables:)
          end
        end
        expect(gql.result.nodes.first).to include('number' => ticket.number)
        expect(gql.result.data).to include('totalCount' => 1, 'collectionSignature' => be_present)
      end

      it 'creates another cache on second call if different cacheTtl is provided' do
        gql.execute(query, variables:)

        ensure_fragment_writes do
          ensure_ticket_queries do
            gql.execute(query, variables: variables.merge({ cacheTtl: cache_ttl + 1 }))
          end
        end
        expect(gql.result.nodes.first).to include('number' => ticket.number)
        expect(gql.result.data).to include('totalCount' => 1, 'collectionSignature' => be_present)
      end

      context 'with a different user with different permissions' do
        let(:other_agent) { create(:agent) }

        it 'does not use the cache on second call' do
          gql.execute(query, variables:)

          gql.graphql_current_user = other_agent

          ensure_fragment_writes do
            ensure_ticket_queries do
              gql.execute(query, variables:)
            end
          end
          expect(gql.result.nodes).to eq([])
          expect(gql.result.data).to include('totalCount' => 0, 'collectionSignature' => '[]')
        end
      end

      context 'with a different user with same permissions' do
        let(:other_agent) { create(:agent, groups: [ticket.group]) }

        context 'with non-personalized overview' do
          it 'uses the cache on second call' do
            gql.execute(query, variables:)

            gql.graphql_current_user = other_agent

            ensure_no_fragment_writes do
              ensure_no_ticket_queries do
                gql.execute(query, variables:)
              end
            end
            expect(gql.result.nodes.first).to include('number' => ticket.number)
            expect(gql.result.data).to include('totalCount' => 1, 'collectionSignature' => be_present)
          end
        end

        context 'with personalized overview' do

          let(:overview) { Overview.find_by(link: 'my_assigned') }

          it 'does not use the cache on second call' do
            gql.execute(query, variables:)

            gql.graphql_current_user = other_agent

            ensure_fragment_writes do
              ensure_ticket_queries do
                gql.execute(query, variables:)
              end
            end
            expect(gql.result.nodes).to eq([])
            expect(gql.result.data).to include('totalCount' => 0, 'collectionSignature' => '[]')
          end
        end
      end

      context 'when knownCollectionSignature is provided' do

        it 'does not use existing cache on second call, because knownCollectionSignature changes' do
          gql.execute(query, variables:)

          ensure_fragment_writes do
            ensure_ticket_queries do
              gql.execute(query, variables: variables.merge({ knownCollectionSignature: gql.result.data[:collectionSignature] }))
            end
          end
          expect(gql.result.data[:edges]).to be_nil
          expect(gql.result.data).to include('totalCount' => 1, 'collectionSignature' => be_present)
        end

        it 'uses cache on third call' do
          gql.execute(query, variables:)
          known_collection_signature = gql.result.data[:collectionSignature]
          gql.execute(query, variables: variables.merge({ knownCollectionSignature: known_collection_signature }))

          ensure_no_fragment_writes do
            ensure_no_ticket_queries do
              gql.execute(query, variables: variables.merge({ knownCollectionSignature: known_collection_signature }))
            end
          end
          expect(gql.result.data[:edges]).to be_nil
          expect(gql.result.data).to include('totalCount' => 1, 'collectionSignature' => be_present)
        end

        it 'skips edges on second call without cache' do
          gql.execute(query, variables:)
          Rails.cache.clear

          ensure_fragment_writes do
            ensure_ticket_queries do
              gql.execute(query, variables: variables.merge({ knownCollectionSignature: gql.result.data[:collectionSignature] }))
            end
          end
          expect(gql.result.data[:edges]).to be_nil
          expect(gql.result.data).to include('totalCount' => 1, 'collectionSignature' => be_present)
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'raises authorization error' do
        gql.execute(query, variables:)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'without authenticated user' do
      before do
        gql.execute(query, variables:)
      end

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
