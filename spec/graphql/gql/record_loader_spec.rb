# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
    let(:tickets_per_loop) { 5 }
    let(:articles_per_ticket) { 1 }
    let(:overview_id) do
      condition = {
        'article.from' => {
          operator: 'contains',
          value:    'record_loader_test.org',
        },
      }
      overview = create(:overview, condition: condition)
      Gql::ZammadSchema.id_from_object(overview, Gql::Types::OverviewType, {})
    end

    it 'performs only the expected amount of DB queries', authenticated_as: :agent do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      query = read_graphql_file('apps/mobile/graphql/fragments/objectAttributeValues.graphql') +
              read_graphql_file('apps/mobile/graphql/queries/ticketsByOverview.graphql')
      variables = { overviewId: overview_id }

      total_queries = {}
      uncached_queries = {}

      result = trace_queries(total_queries, uncached_queries) do
        graphql_execute(query, variables: variables)
      end
      expect(result['data']['ticketsByOverview']['edges'].count).to eq(10)

      expect(total_queries).to include(
        {
          'Overview Load'          => 1,
          'ObjectLookup Load'      => 1,
          'Permission Load'        => 25,
          'Permission Exists?'     => 24,
          'Group Load'             => 11,
          'UserGroup Exists?'      => 10,
          'Ticket Load'            => 1,
          'Ticket Exists?'         => 1,
          'User Load'              => 1,
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
          'Permission Load'        => 4,
          'Permission Exists?'     => 4,
          'Group Load'             => 3,
          'UserGroup Exists?'      => 2,
          'Ticket Load'            => 1,
          'Ticket Exists?'         => 1,
          'User Load'              => 1,
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
    let(:tickets_per_loop) { 1 }
    let(:articles_per_ticket) { 100 }
    let(:ticket_id) { Gql::ZammadSchema.id_from_object(Ticket.last, Gql::Types::TicketType, {}) }

    it 'performs only the expected amount of DB queries', authenticated_as: :agent do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      query = read_graphql_file('apps/mobile/graphql/fragments/objectAttributeValues.graphql') +
              read_graphql_file('apps/mobile/graphql/queries/ticketById.graphql')
      variables = { ticketId: ticket_id, withArticles: true }

      total_queries = {}
      uncached_queries = {}

      result = trace_queries(total_queries, uncached_queries) do
        graphql_execute(query, variables: variables)
      end

      expect(result['data']['ticketById']['id']).to eq(ticket_id)

      expect(total_queries).to include(
        {
          'Permission Load'        => 5,
          'Permission Exists?'     => 4,
          # The next lines are unfortunately high, caused by Pundit layer, but mitigated by SQL cache.
          'Group Load'             => 102,
          'UserGroup Exists?'      => 101,
          'Ticket Load'            => 101,
          'Ticket::Article Load'   => 1,
          'User Load'              => 1,
          'Organization Load'      => 1,
          'Ticket::State Load'     => 1,
          'Ticket::Priority Load'  => 1,
          'Ticket::StateType Load' => 1
        }
      )

      expect(uncached_queries).to include(
        {
          'Permission Load'        => 3,
          'Permission Exists?'     => 3,
          'Group Load'             => 2,
          'UserGroup Exists?'      => 1,
          'Ticket Load'            => 2,
          'Ticket::Article Load'   => 1,
          'User Load'              => 1,
          'Organization Load'      => 1,
          'Ticket::State Load'     => 1,
          'Ticket::Priority Load'  => 1,
          'Ticket::StateType Load' => 1
        }
      )
    end
  end
end
