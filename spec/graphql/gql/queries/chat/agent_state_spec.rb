# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Which topics, sessions, agents and seats an agent gets is covered by
#   spec/services/service/chat/agent_state_spec.rb — this covers the GraphQL surface only.
RSpec.describe Gql::Queries::Chat::AgentState, type: :graphql do
  let(:query) do
    <<~GQL
      query chatAgentState {
        chatAgentState {
          active
          topics {
            id
            internalId
            name
            active
          }
          waitingQueues {
            topic {
              id
              name
            }
            sessions {
              id
              internalId
              state
              name
              url
              remoteIp
              dnsName
              geoIp {
                countryName
                cityName
              }
              user {
                id
              }
              messages {
                id
              }
            }
          }
          runningSessions {
            id
            state
            topic {
              id
            }
            user {
              id
              firstname
              lastname
            }
            messages {
              id
              content
              createdBy {
                id
              }
            }
          }
          availableAgents {
            id
            firstname
            lastname
          }
          seatsAvailable
          seatsTotal
        }
      }
    GQL
  end

  let(:chat_enabled) { true }
  let(:topic)        { create(:chat, name: 'Support') }
  let(:preferences)  { { chat: { active: { topic.id.to_s => 'on' } } } }
  let(:agent)        { create(:agent, firstname: 'Chat', lastname: 'Agent', preferences:) }
  let(:colleague)    { create(:agent, firstname: 'Other', lastname: 'Agent', preferences:) }
  let(:waiting) do
    create(:'chat/session', chat: topic, state: 'waiting', preferences: {
             url:       'https://example.com/pricing',
             remote_ip: '203.0.113.5',
             dns_name:  'host.example.com',
             geo_ip:    { country_name: 'Germany', city_name: 'Berlin' },
           })
  end
  let(:running)          { create(:'chat/session', chat: topic, state: 'running', user: colleague) }
  let(:customer_message) { create(:'chat/message', chat_session: running, content: 'Hello', created_by_id: nil) }
  let(:agent_message)    { create(:'chat/message', chat_session: running, content: 'Hi there', created_by: colleague) }

  before do
    Setting.set('chat', chat_enabled)
    create(:'chat/agent', concurrent: 4, updated_by: agent, created_by: agent)
    create(:'chat/agent', concurrent: 2, updated_by: colleague, created_by: colleague)
    waiting
    customer_message
    agent_message
    gql.execute(query)
  end

  context 'with a chat agent', authenticated_as: :agent do
    it 'returns the availability, the topics, the agents and the seats', :aggregate_failures do
      expect(gql.result.data).to include('active' => true, 'seatsAvailable' => 4, 'seatsTotal' => 6)
      expect(gql.result.data['topics']).to include({ 'id' => gql.id(topic), 'internalId' => topic.id, 'name' => 'Support', 'active' => true })
      expect(gql.result.data['availableAgents']).to contain_exactly(
        { 'id' => gql.id(agent), 'firstname' => 'Chat', 'lastname' => 'Agent' },
        { 'id' => gql.id(colleague), 'firstname' => 'Other', 'lastname' => 'Agent' },
      )
    end

    it 'returns the waiting customers per topic with their connection details' do
      expect(gql.result.data['waitingQueues']).to eq([
                                                       {
                                                         'topic'    => { 'id' => gql.id(topic), 'name' => 'Support' },
                                                         'sessions' => [
                                                           {
                                                             'id'         => gql.id(waiting),
                                                             'internalId' => waiting.id,
                                                             'state'      => 'waiting',
                                                             'name'       => nil,
                                                             'url'        => 'https://example.com/pricing',
                                                             'remoteIp'   => '203.0.113.5',
                                                             'dnsName'    => 'host.example.com',
                                                             'geoIp'      => { 'countryName' => 'Germany', 'cityName' => 'Berlin' },
                                                             'user'       => nil,
                                                             'messages'   => [],
                                                           },
                                                         ],
                                                       },
                                                     ])
    end

    # A colleague's conversation is readable too, as a session found through search opens for any chat agent.
    it 'returns the running sessions with their agent and their conversation' do
      expect(gql.result.data['runningSessions']).to eq([
                                                         {
                                                           'id'       => gql.id(running),
                                                           'state'    => 'running',
                                                           'topic'    => { 'id' => gql.id(topic) },
                                                           'user'     => { 'id' => gql.id(colleague), 'firstname' => 'Other', 'lastname' => 'Agent' },
                                                           'messages' => [
                                                             { 'id' => gql.id(customer_message), 'content' => 'Hello', 'createdBy' => nil },
                                                             { 'id' => gql.id(agent_message), 'content' => 'Hi there', 'createdBy' => { 'id' => gql.id(colleague) } },
                                                           ],
                                                         },
                                                       ])
    end

    context 'with a running session of the agent' do
      let(:own_running) { create(:'chat/session', chat: topic, state: 'running', user: agent) }
      let(:own_first)   { create(:'chat/message', chat_session: own_running, content: 'Hello', created_by_id: nil) }
      let(:own_second)  { create(:'chat/message', chat_session: own_running, content: 'Hi there', created_by: agent) }

      before do
        own_first
        own_second
        gql.execute(query)
      end

      it 'returns the conversation of every session, oldest first', :aggregate_failures do
        sessions = gql.result.data['runningSessions'].index_by { |session| session['id'] }

        expect(sessions[gql.id(own_running)]['messages'].map { |message| message.slice('id', 'content') }).to eq([
                                                                                                                   { 'id' => gql.id(own_first), 'content' => 'Hello' },
                                                                                                                   { 'id' => gql.id(own_second), 'content' => 'Hi there' },
                                                                                                                 ])
        expect(sessions[gql.id(running)]['messages'].map { |message| message.slice('id', 'content') }).to eq([
                                                                                                               { 'id' => gql.id(customer_message), 'content' => 'Hello' },
                                                                                                               { 'id' => gql.id(agent_message), 'content' => 'Hi there' },
                                                                                                             ])
      end
    end

    context 'when the chat feature is switched off' do
      let(:chat_enabled) { false }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    # Whoever wrote a message and whoever runs a session is looked up in a batch, so with a first
    #   batch of conversations in place, more of them must not add a query.
    context 'with more sessions' do
      def query_count(*sql_parts)
        queries = []
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
          queries << payload[:sql] if sql_parts.any? { |sql_part| payload[:sql].include?(sql_part) }
        end
        gql.execute(query)
        queries.size
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      # Every conversation carries its messages, the colleagues' as well as the agent's own.
      def add_conversations
        create_list(:agent, 3, preferences:).each do |other_agent|
          conversation = create(:'chat/session', chat: topic, state: 'running', user: other_agent)
          create(:'chat/message', chat_session: conversation, created_by: other_agent)

          own_conversation = create(:'chat/session', chat: topic, state: 'running', user: agent)
          create(:'chat/message', chat_session: own_conversation, created_by: agent)
        end

        # The first request after creating users fills their lookup cache once; count what a request costs after.
        gql.execute(query)
      end

      before { add_conversations }

      it 'batch-loads the messages of all sessions in a single query' do
        expect { add_conversations }.not_to change { query_count('FROM "chat_messages"') }
      end

      # A single key loads with `=`, several with `IN`; either way one query, not one per session.
      it 'batch-loads the agents of all sessions in a single query' do
        expect { add_conversations }.not_to change { query_count('"users"."id" IN', '"users"."id" =') }
      end

      it 'batch-loads the topic of all sessions in a single query' do
        expect { add_conversations }.not_to change { query_count('FROM "chats"') }
      end
    end
  end

  # Their UserPolicy#nested_show? row is what lets them read the names of the other agents.
  context 'with a chat agent without ticket permissions', authenticated_as: :agent do
    let(:agent) { create(:user, firstname: 'Chat', lastname: 'Agent', roles: [create(:role, permission_names: 'chat.agent')], preferences:) }

    it 'sees the other agents by name', :aggregate_failures do
      expect(gql.result.data['availableAgents']).to include('id' => gql.id(colleague), 'firstname' => 'Other', 'lastname' => 'Agent')
      expect(gql.result.data['runningSessions'].first['user']).to eq('id' => gql.id(colleague), 'firstname' => 'Other', 'lastname' => 'Agent')
    end
  end

  context 'with a user without the chat.agent permission', authenticated_as: :user do
    let(:user) { create(:user, roles: [create(:role, permission_names: 'ticket.agent')]) }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
