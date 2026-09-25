# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Which calls a user gets to see is covered by spec/services/service/cti/log/list_spec.rb —
#   this covers the GraphQL surface only: the node fields, the connection, and authorization.
RSpec.describe Gql::Queries::Cti::Logs, type: :graphql do
  let(:query) do
    <<~GQL
      query ctiLogs($first: Int) {
        ctiLogs(first: $first) {
          edges {
            node {
              id
              direction
              state
              comment
              from
              to
              fromPretty
              toPretty
              fromComment
              toComment
              done
              durationWaitingTime
              durationTalkingTime
              createdAt
              fromMatches { level comment user { id firstname lastname fullname } }
              toMatches { level comment user { id firstname lastname fullname } }
            }
          }
          pageInfo { hasNextPage }
        }
      }
    GQL
  end
  let(:first)     { nil }
  let(:variables) { { first: }.compact }

  let(:customer) { create(:customer, firstname: 'Franz', lastname: 'Bauer') }
  let(:log) do
    create(:cti_log,
           direction:             'in',
           state:                 'hangup',
           comment:               'normalClearing',
           from:                  '4930609854180',
           to:                    '4930609811111',
           to_comment:            'Bob Smith',
           done:                  true,
           duration_waiting_time: 20,
           duration_talking_time: 45,
           preferences:           {
             from: [
               { caller_id: '4930609854180', comment: nil, level: 'known', object: 'User', o_id: customer.id, user_id: customer.id },
               { caller_id: '4930609854180', comment: 'From signature', level: 'maybe', object: 'User', o_id: customer.id, user_id: nil },
             ],
           })
  end

  before do
    log
    gql.execute(query, variables:)
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'returns the call with its fields', :aggregate_failures do
      node = gql.result.nodes.first

      expect(node).to include(
        'id'                  => gql.id(log),
        'direction'           => 'in',
        'state'               => 'hangup',
        'comment'             => 'normalClearing',
        'from'                => '4930609854180',
        'to'                  => '4930609811111',
        'fromPretty'          => '+49 30 609854180',
        'toPretty'            => '+49 30 609811111',
        'fromComment'         => nil,
        'toComment'           => 'Bob Smith',
        'done'                => true,
        'durationWaitingTime' => 20,
        'durationTalkingTime' => 45,
        'toMatches'           => [],
      )
      expect(node['fromMatches']).to eq([
                                          { 'level' => 'known', 'comment' => nil, 'user' => { 'id' => gql.id(customer), 'firstname' => 'Franz', 'lastname' => 'Bauer', 'fullname' => 'Franz Bauer' } },
                                          { 'level' => 'maybe', 'comment' => 'From signature', 'user' => nil },
                                        ])
    end

    context 'when the stored pretty values are missing' do
      let(:log) { create(:cti_log, from: '4930609854180').tap { |record| record.update_column(:preferences, nil) } }

      it 'generates them on the fly' do
        expect(gql.result.nodes.first).to include('fromPretty' => '+49 30 609854180')
      end
    end

    context 'with matches pointing to several users' do
      def user_query_count
        queries = []
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
          queries << payload[:sql] if payload[:sql].include?('"users"."id" IN') || payload[:sql].include?('"users"."id" =')
        end
        gql.execute(query, variables:)
        queries.size
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      # The session's own user lookups are constant; only a lookup per match would grow with the log.
      it 'batch-loads the matched users in a single query' do
        expect do
          create_list(:customer, 3).each do |other_customer|
            create(:cti_log, preferences: { from: [{ level: 'maybe', user_id: other_customer.id }], to: [{ level: 'known', user_id: customer.id }] })
          end
        end.not_to change { user_query_count }
      end
    end

    context 'when paginating' do
      let(:first) { 1 }

      before do
        create(:cti_log)
        gql.execute(query, variables:)
      end

      it 'has a next page', :aggregate_failures do
        expect(gql.result.nodes.size).to eq(1)
        expect(gql.result.data['pageInfo']).to include('hasNextPage' => true)
      end
    end
  end

  # The old caller log ships the matched users to anyone with cti.agent, cut down to the customer-level fields.
  context 'with a user whose role holds cti.agent only', authenticated_as: :user do
    let(:user) { create(:user, roles: [create(:role, permission_names: 'cti.agent')]) }

    it 'resolves the matched user with the name fields only' do
      expect(gql.result.nodes.first['fromMatches'].first['user']).to eq({ 'id' => gql.id(customer), 'firstname' => 'Franz', 'lastname' => 'Bauer', 'fullname' => nil })
    end
  end

  context 'with a user without the cti.agent permission', authenticated_as: :user do
    let(:user) { create(:user, roles: [create(:role, permission_names: 'ticket.agent')]) }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
