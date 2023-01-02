# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::RecordLoader, type: :graphql do

  let(:agent) { create(:agent) }
  let(:debug) { false }

  before do
    loops.times do
      organization   = create(:organization)
      user           = create(:user, organization: organization)
      group          = create(:group)

      tickets_per_loop.times do
        source_ticket = create(:ticket, customer: user, organization: organization, group: group, created_by_id: user.id, state: Ticket::State.all.sample)
        if articles_per_ticket
          create_list(:ticket_article, articles_per_ticket, ticket_id: source_ticket.id, from: 'asdf1@record_loader_test.org', created_by_id: user.id)
        end
      end

      agent.group_names_access_map = Group.all.to_h { |g| [g.name, ['full']] }
    end
  end

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
    let(:loops) { 5 }
    let(:tickets_per_loop)    { 5 }
    let(:articles_per_ticket) { 1 }
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

    it 'performs only the expected amount of DB queries', :aggregate_failures, authenticated_as: :agent do
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
          'Permission Load'        => 56,
          'Permission Exists?'     => 55,
          'Group Load'             => 11,
          'UserGroup Exists?'      => 20,
          'Ticket Load'            => 1,
          'Ticket Exists?'         => 1,
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
          'Permission Load'        => 6,
          'Permission Exists?'     => 6,
          'Group Load'             => 3,
          'UserGroup Exists?'      => 2,
          'Ticket Load'            => 1,
          'Ticket Exists?'         => 1,
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
    let(:loops) { 1 }
    let(:tickets_per_loop)    { 1 }
    let(:articles_per_ticket) { 10 }
    let(:ticket_id)           { gql.id(Ticket.last) }
    let(:query) do
      <<~QUERY
        query ticket(
          $ticketId: ID
          $withArticles: Boolean = false
        ) {
          ticket(
            ticket: {
              ticketId: $ticketId
            }
          ) {
            id
            internalId
            number
            title
            createdAt
            updatedAt
            owner {
              firstname
              lastname
            }
            customer {
              id
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
                name
              }
            }
            group {
              name
            }
            priority {
              name
              defaultCreate
              uiColor
            }
            articles @include(if: $withArticles) {
              edges {
                node {
                  id
                  internal
                  body
                  createdAt
                  sender {
                    name
                  }
                  subject
                  internal
                }
              }
            }
          }
        }
      QUERY
    end

    it 'performs only the expected amount of DB queries', :aggregate_failures, authenticated_as: :agent do
      variables = { ticketId: ticket_id, withArticles: true }
      total_queries = {}
      uncached_queries = {}

      trace_queries(total_queries, uncached_queries) do
        gql.execute(query, variables: variables)
      end

      expect(gql.result.data['id']).to eq(ticket_id)

      expect(total_queries).to include(
        {
          'Permission Load'              => 8,
          'Permission Exists?'           => 7,
          'Group Load'                   => 12,
          'UserGroup Exists?'            => 13,
          'Ticket Load'                  => 11,
          'Ticket::Article Load'         => 1,
          'Ticket::Article::Sender Load' => 1,
          'User Load'                    => 2,
          'Organization Load'            => 1,
          'Ticket::State Load'           => 1,
          'Ticket::Priority Load'        => 1,
          'Ticket::StateType Load'       => 1
        }
      )

      adapter = ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]

      expect(uncached_queries).to include(
        {
          'Permission Load'        => 4,
          'Permission Exists?'     => 4,
          'Group Load'             => 2,
          'UserGroup Exists?'      => 1,
          'Ticket Load'            => adapter == 'mysql2' ? 1 : 2,  # differs for some reason, not sure why
          'Ticket::Article Load'   => 1,
          'User Load'              => 2,
          'Organization Load'      => 1,
          'Ticket::State Load'     => 1,
          'Ticket::Priority Load'  => 1,
          'Ticket::StateType Load' => 1
        }
      )
    end
  end
end
