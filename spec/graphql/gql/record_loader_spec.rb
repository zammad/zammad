# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::RecordLoader, :aggregate_failures, authenticated_as: :agent, type: :graphql do

  let(:agent) { create(:agent) }
  let(:debug) { false }

  def trace_queries(total_queries, uncached_queries)
    callback = lambda do |*, payload|
      total_queries[payload[:name]] ||= 0
      total_queries[payload[:name]] += 1

      if !payload[:cached]
        uncached_queries[payload[:name]] ||= 0
        uncached_queries[payload[:name]] += 1
      end
      next if !debug

      # rubocop:disable Rails/Output
      puts payload[:name], payload[:sql], payload[:cached]
      caller.reject { |line| line.match(%r{gems|spec}) }.first(30).each do |relevant_caller_line|
        puts("  ↳ #{relevant_caller_line.sub(Rails.root.join('/').to_s, '')}")
      end
      puts ''
      # rubocop:enable Rails/Output
    end

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
      ActiveRecord::Base.cache do
        # ActiveRecord::Base.logger = Logger.new(STDOUT)
        return yield
      end
    end
  end

  context 'when querying multiple tickets' do
    before do
      5.times do
        organization   = create(:organization)
        user           = create(:user, organization: organization)
        group          = create(:group)

        5.times do
          source_ticket = create(:ticket, customer: user, organization: organization, group: group, created_by_id: user.id, state: Ticket::State.all.sample)
          create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf1@record_loader_test.org', created_by_id: user.id)
        end

        agent.group_names_access_map = Group.all.to_h { |g| [g.name, ['full']] }
      end
    end

    let(:overview_id) do
      condition = {
        'article.from' => {
          operator: 'contains',
          value:    'record_loader_test.org',
        },
      }
      overview = create(:overview, condition: condition)
      gql.id(overview)
    end
    let(:query) do
      <<~QUERY
        query ticketsByOverview(
          $overviewId: ID!
          $pageSize: Int = 10
        ) {
          ticketsByOverview(
            overviewId: $overviewId
            first: $pageSize
          ) {
            totalCount
            edges {
              node {
                id
                internalId
                number
                title
                createdAt
                updatedAt
                owner {
                  firstname
                  lastname
                  fullname
                }
                customer {
                  firstname
                  lastname
                  fullname
                }
                organization {
                  name
                }
                state {
                  name
                  stateType {
                    id
                    name
                  }
                }
                group {
                  name
                }
                priority {
                  name
                  uiColor
                  defaultCreate
                }
              }
              cursor
            }
            pageInfo {
              endCursor
              hasNextPage
            }
          }
        }
      QUERY
    end

    it 'performs only the expected amount of DB queries' do
      # Create variables here and not via let(), otherwise the objects would be instantiated later in the traced block.
      variables = { overviewId: overview_id }
      total_queries = {}
      uncached_queries = {}

      trace_queries(total_queries, uncached_queries) do
        gql.execute(query, variables: variables)
      end
      expect(gql.result.nodes.count).to eq(10)

      expect(total_queries).to include(
        {
          'Overview Load'          => 1,
          'ObjectLookup Load'      => 1,
          'Permission Load'        => 5,
          'Group Load'             => 11,
          'UserGroup Exists?'      => 4,
          'Ticket Load'            => 1,
          # 'Ticket Exists?'         => 1,
          'User Load'              => 2,
          'Organization Load'      => 1,
          'Ticket::State Load'     => 1,
          'Ticket::Priority Load'  => 1,
          'Ticket::StateType Load' => 1
        }
      )

      expect(uncached_queries).to include(
        {
          'Overview Load'          => 1,
          'ObjectLookup Load'      => 1,
          'Permission Load'        => 5,
          'Group Load'             => 3,
          'UserGroup Exists?'      => 4,
          'Ticket Load'            => 1,
          # 'Ticket Exists?'         => 1,
          'User Load'              => 2,
          'Organization Load'      => 1,
          'Ticket::State Load'     => 1,
          'Ticket::Priority Load'  => 1,
          'Ticket::StateType Load' => 1
        }
      )
    end
  end

  context 'when querying one ticket with many articles' do
    before do
      create_list(:user, 10, organization: create(:organization))
    end

    let(:organization_id) { gql.id(Organization.last) }
    let(:query) do
      <<~QUERY
        query organization($organizationId: ID, $organizationInternalId: Int) {
          organization( organization: { organizationId: $organizationId, organizationInternalId: $organizationInternalId } ) {
            id
            name
            shared
            domain
            domainAssignment
            active
            note
            ticketsCount {
              open
              closed
            }
            members{
              edges {
                node {
                  firstname
                  lastname
                }
              }
            }
          }
        }
      QUERY
    end

    it 'performs only the expected amount of DB queries' do
      variables = { organizationId: organization_id }
      total_queries = {}
      uncached_queries = {}

      trace_queries(total_queries, uncached_queries) do
        gql.execute(query, variables: variables)
      end

      expect(gql.result.data[:id]).to eq(organization_id)

      expect(total_queries).to include(
        {
          'Permission Load'   => 3,
          'User Load'         => 2,
          'Organization Load' => 1,
        }
      )

      expect(uncached_queries).to include(
        {
          'Permission Load'   => 3,
          'User Load'         => 2,
          'Organization Load' => 1,
        }
      )
    end
  end
end
