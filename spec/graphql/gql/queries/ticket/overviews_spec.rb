# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::Overviews, type: :graphql do

  context 'when fetching ticket overviews' do
    let(:agent)     { create(:agent) }
    let(:query)     do
      <<~QUERY
        query ticketOverviews(
          $ignoreUserConditions: Boolean!,
          $withTicketCount: Boolean!,
          $withCachedTicketCount: Boolean!
          $cacheTtl: Int!
          $filterOverviewIds: [ID!]
        ) {
          ticketOverviews(ignoreUserConditions: $ignoreUserConditions, filterOverviewIds: $filterOverviewIds) {
            id
            name
            link
            prio
            orderBy
            orderDirection
            organizationShared
            outOfOffice
            groupBy
            groupDirection
            viewColumnsRaw
            viewColumns {
              key
              value
            }
            orderColumns {
              key
              value
            }
            active
            ticketCount @include(if: $withTicketCount)
            cachedTicketCount(cacheTtl: $cacheTtl) @include(if: $withCachedTicketCount)
          }
        }
      QUERY
    end
    let(:ignore_user_conditions) { false }
    let(:with_ticket_count)        { false }
    let(:with_cached_ticket_count) { false }
    let(:cache_ttl)                { 4.seconds }
    let(:filter_overview_ids)      { nil }
    let(:variables) do
      {
        withTicketCount:       with_ticket_count,
        withCachedTicketCount: with_cached_ticket_count,
        ignoreUserConditions:  ignore_user_conditions,
        cacheTtl:              cache_ttl,
        filterOverviewIds:     filter_overview_ids,
      }
    end

    context 'with an agent', authenticated_as: :agent do
      before do
        gql.execute(query, variables: variables)
      end

      it 'has agent overview' do
        expect(gql.result.data.first).to include('name' => 'My Assigned Tickets', 'link' => 'my_assigned', 'prio' => 1000, 'active' => true, 'groupBy' => nil, 'groupDirection' => nil)
      end

      it 'has view and order columns' do
        expect(gql.result.data.first).to include(
          'viewColumnsRaw' => match_array(%w[title customer_id group_id created_at]),
          'viewColumns'    => include({ 'key' => 'title', 'value' => 'Title' }),
          'orderColumns'   => include({ 'key' => 'created_at', 'value' => 'Created at' }),
        )
      end

      it 'has shared organization and out of office fields' do
        expect(gql.result.data.first).to include(
          'organizationShared' => false,
          'outOfOffice'        => false,
        )
      end

      context 'with object attributes and unknown attributes', db_strategy: :reset do
        let(:oa) do
          create(:object_manager_attribute_text, :required_screen).tap do
            ObjectManager::Attribute.migration_execute
          end
        end
        # Change the overview to include an object attribute column and a column that has an unknown field.
        let(:overview) do
          Overview.find_by('link' => 'my_assigned').tap do |overview|
            overview.view = { 's' => [oa.name, 'unknown_field'] }
            overview.save!
          end
        end
        let(:with_ticket_count) do
          overview
          false
        end

        it 'lists view columns correctly' do
          expect(gql.result.data.first).to include(
            'viewColumns' => [ { 'key' => oa.name, 'value' => oa.display }, { 'key' => 'unknown_field', 'value' => nil }],
          )
        end
      end

      context 'when not ignoring user conditions' do
        it 'does not include replacement tickets overview' do
          expect(gql.result.data).not_to include(include('name' => 'My Replacement Tickets', 'outOfOffice' => true))
        end
      end

      context 'when ignoring user conditions' do
        let(:ignore_user_conditions) { true }

        it 'includes replacement tickets overview' do
          expect(gql.result.data).to include(include('name' => 'My Replacement Tickets', 'outOfOffice' => true))
        end
      end

      context 'without ticket count' do
        it 'does not include ticketCount field' do
          expect(gql.result.data.first).not_to have_key('ticketCount')
        end
      end

      context 'with ticket count' do
        let(:with_ticket_count) { true }

        it 'includes ticketCount field' do
          expect(gql.result.data.first['ticketCount']).to eq(0)
        end
      end
    end

    context 'with an agent, with filtering and caching', authenticated_as: :agent do
      def trace_queries(queries, &)
        callback = lambda do |*, payload|
          queries[payload[:name]] ||= 0
          queries[payload[:name]] += 1
        end
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)
        queries
      end

      def ensure_no_ticket_queries(&)
        queries = trace_queries({}, &)
        expect(queries).not_to have_key('Ticket Count')
      end

      def ensure_ticket_queries(&)
        queries = trace_queries({}, &)
        expect(queries).to have_key('Ticket Count')
      end

      def ensure_cache_writes
        allow(Rails.cache).to receive(:write).and_call_original
        yield
        expect(Rails.cache).to have_received(:write).at_least(:once)
      end

      def ensure_no_cache_writes
        allow(Rails.cache).to receive(:write).and_call_original
        yield
        expect(Rails.cache).not_to have_received(:write)
      end

      let(:agent) { create(:agent, groups: [ticket.group]) }
      let!(:ticket)                  { create(:ticket) }
      let(:overview)                 { Overview.find_by(link: 'all_unassigned') }
      let(:filter_overview_ids)      { [gql.id(overview)] }
      let(:with_cached_ticket_count) { true }

      it 'creates a cache on first call' do
        ensure_cache_writes do
          ensure_ticket_queries do
            gql.execute(query, variables:)
          end
        end
        expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 1))
      end

      it 'uses the cache on second call' do
        gql.execute(query, variables:)

        ensure_no_cache_writes do
          ensure_no_ticket_queries do
            gql.execute(query, variables:)
          end
        end
        expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 1))
      end

      it 'recreates the cache on second call if cache has expired' do
        freeze_time
        gql.execute(query, variables:)
        travel(cache_ttl)

        ensure_cache_writes do
          ensure_ticket_queries do
            gql.execute(query, variables:)
          end
        end
        expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 1))
      end

      it 'creates another cache on second call if different cacheTtl is provided' do
        gql.execute(query, variables:)

        ensure_cache_writes do
          ensure_ticket_queries do
            gql.execute(query, variables: variables.merge({ cacheTtl: cache_ttl + 1 }))
          end
        end
        expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 1))
      end

      context 'with a different user with different permissions' do
        let(:other_agent) { create(:agent) }

        it 'does not use the cache on second call' do
          gql.execute(query, variables:)

          gql.graphql_current_user = other_agent

          ensure_cache_writes do
            ensure_ticket_queries do
              gql.execute(query, variables:)
            end
          end
          expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 0))
        end
      end

      context 'with several overviews' do
        let(:filter_overview_ids) { Overview.where(link: %w[all_unassigned all_open all_escalated]).map { |overview| gql.id(overview) } }

        it 'looks the group access up once per request on a cached call', :aggregate_failures do
          gql.execute(query, variables:)

          # A request starts without the request cache of the one before.
          Auth::RequestCache.clear
          queries = trace_queries({}) { gql.execute(query, variables:) }

          expect(queries).not_to have_key('Ticket Count')
          expect(queries['UserGroup Pluck']).to eq(2)
          expect(queries['RoleGroup Pluck']).to eq(2)
        end
      end

      context 'with a different user who may see the overview\'s tickets in overviews only' do
        let(:other_agent) { create(:agent).tap { |other| other.group_ids_access_map = { ticket.group.id => 'overview' } } }

        it 'does not share the cache, whoever fills it first', :aggregate_failures do
          gql.execute(query, variables:)
          gql.graphql_current_user = other_agent
          ensure_cache_writes do
            gql.execute(query, variables:)
          end

          Rails.cache.clear
          gql.execute(query, variables:)
          gql.graphql_current_user = agent
          ensure_cache_writes do
            gql.execute(query, variables:)
          end
          expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 1))
        end
      end

      context 'with a different user with same permissions' do
        let(:other_agent) { create(:agent, groups: [ticket.group]) }

        context 'with non-personalized overview' do
          it 'uses the cache on second call' do
            gql.execute(query, variables:)

            gql.graphql_current_user = other_agent

            ensure_no_cache_writes do
              ensure_no_ticket_queries do
                gql.execute(query, variables:)
              end
            end
            expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 1))
          end
        end

        context 'with personalized overview' do

          let(:overview) { Overview.find_by(link: 'my_assigned') }

          it 'does not use the cache on second call' do
            gql.execute(query, variables:)

            gql.graphql_current_user = other_agent

            ensure_cache_writes do
              ensure_ticket_queries do
                gql.execute(query, variables:)
              end
            end
            expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 0))
          end
        end

        context 'when the users are customers as well' do
          let(:agent)       { create(:agent_and_customer, groups: [ticket.group]) }
          let(:other_agent) { create(:agent_and_customer, groups: [ticket.group]) }

          context 'with an own ticket outside the group permissions excluded by the overview' do
            before { create(:ticket, customer: agent, group: create(:group), state: Ticket::State.find_by(name: 'closed')) }

            it 'uses the cache on second call', :aggregate_failures do
              gql.execute(query, variables:)

              gql.graphql_current_user = other_agent

              ensure_no_cache_writes do
                ensure_no_ticket_queries do
                  gql.execute(query, variables:)
                end
              end
              expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 1))
            end
          end

          context 'with an own ticket outside the group permissions created while the cache is filled' do
            let(:created_ticket) { create(:ticket, customer: agent, group: create(:group)) }

            before do
              allow(Ticket::Overviews::CachePartition).to receive(:new).and_wrap_original do |original, *args|
                original.call(*args).tap { created_ticket }
              end
            end

            it 'does not pass it on to the other user' do
              gql.execute(query, variables:)

              gql.graphql_current_user = other_agent
              gql.execute(query, variables:)

              expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 1))
            end
          end

          context 'with a personalized overview and an own ticket outside the group permissions' do
            let(:overview) { create(:overview, condition: { 'ticket.customer_id' => { operator: 'is', pre_condition: 'current_user.id' } }) }

            before { create(:ticket, customer: agent, group: create(:group)) }

            it 'leaves the cache behind together with the customer permission', :aggregate_failures do
              gql.execute(query, variables:)
              expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 1))

              agent.update!(roles: Role.where(name: 'Agent'))
              Auth::RequestCache.clear
              gql.graphql_current_user = agent.reload

              ensure_cache_writes do
                ensure_ticket_queries do
                  gql.execute(query, variables:)
                end
              end
              expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 0))
            end
          end

          context 'with an own ticket outside the group permissions' do
            before { create(:ticket, customer: agent, group: create(:group)) }

            it 'does not use the cache on second call', :aggregate_failures do
              gql.execute(query, variables:)
              expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 2))

              gql.graphql_current_user = other_agent

              ensure_cache_writes do
                ensure_ticket_queries do
                  gql.execute(query, variables:)
                end
              end
              expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 1))
            end
          end

          context 'with own tickets only inside the group permissions' do
            before { create(:ticket, customer: agent, group: ticket.group) }

            it 'uses the cache on second call', :aggregate_failures do
              gql.execute(query, variables:)

              gql.graphql_current_user = other_agent

              ensure_no_cache_writes do
                ensure_no_ticket_queries do
                  gql.execute(query, variables:)
                end
              end
              expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 2))
            end
          end
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      before do
        gql.execute(query, variables: variables)
      end

      let(:customer) { create(:customer) }

      it 'has customer overview' do
        expect(gql.result.data.first).to include('name' => 'My Tickets', 'link' => 'my_tickets', 'prio' => 1100, 'active' => true,)
      end

      context 'with a non-personalized overview for customers, with caching' do
        let(:overview)                 { create(:overview, role_ids: [Role.find_by(name: 'Customer').id]) }
        let(:filter_overview_ids)      { [gql.id(overview)] }
        let(:with_cached_ticket_count) { true }
        let(:other_customer)           { create(:customer) }

        before { create(:ticket, customer:) }

        it 'does not share the count with another customer', :aggregate_failures do
          gql.execute(query, variables:)
          expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 1))

          gql.graphql_current_user = other_customer
          gql.execute(query, variables:)
          expect(gql.result.data).to contain_exactly(include('cachedTicketCount' => 0))
        end
      end

      context 'when not ignoring user conditions' do
        it 'does not include shared organization overview' do
          expect(gql.result.data).not_to include(include('name' => 'My Organization Tickets', 'organizationShared' => true))
        end
      end

      context 'when ignoring user conditions' do
        let(:ignore_user_conditions) { true }

        it 'includes replacement tickets overview' do
          expect(gql.result.data).to include(include('name' => 'My Organization Tickets', 'organizationShared' => true))
        end
      end
    end

    context 'with unauthenticated users' do
      before do
        gql.execute(query, variables: variables)
      end

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
