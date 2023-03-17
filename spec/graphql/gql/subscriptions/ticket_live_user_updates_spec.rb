# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::TicketLiveUserUpdates, :aggregate_failures, authenticated_as: :agent, type: :graphql do
  let(:agent)                         { create(:agent) }
  let(:customer)                      { create(:customer) }
  let(:ticket)                        { create(:ticket) }
  let(:live_user_entry)               { create(:taskbar, key: "Ticket-#{ticket.id}", user_id: agent.id, app: 'mobile', state: { editing: true }) }
  let(:live_user_entry_customer)      { create(:taskbar, key: "Ticket-#{ticket.id}", user_id: customer.id, app: 'mobile', state: { editing: false }) }

  let(:mock_channel) { build_mock_channel }
  let(:variables) { { userId: Gql::ZammadSchema.id_from_object(agent), key: "Ticket-#{ticket.id}", app: 'mobile' } }
  let(:subscription) do
    <<~QUERY
      subscription ticketLiveUserUpdates($userId: ID!, $key: String!, $app: EnumTaskbarApp!) {
        ticketLiveUserUpdates(userId: $userId, key: $key, app: $app) {
          liveUsers {
            user {
              firstname
              lastname
            }
            apps {
              name
              editing
              lastInteraction
            }
          }
        }
      }
    QUERY
  end

  before do
    live_user_entry && live_user_entry_customer

    gql.execute(subscription, variables: variables, context: { channel: mock_channel })
  end

  def update_taskbar_item(taskbar_item, state, agent_id)
    # Special case: By design, it is only allowed to update the taskbar of the current user.
    # We need to work around this, otherwise this test would fail.
    UserInfo.current_user_id = agent_id
    taskbar_item.update!(state: state)
    UserInfo.current_user_id = agent.id
  end

  context 'when subscribed' do
    it 'subscribes and delivers initial data' do
      expect(gql.result.data['liveUsers'].size).to eq(2)
      expect(gql.result.data['liveUsers'].first).to include('user' => {
                                                              'firstname' => agent.firstname,
                                                              'lastname'  => agent.lastname,
                                                            })

      expect(gql.result.data['liveUsers'].last).to include('user' => {
                                                             'firstname' => customer.firstname,
                                                             'lastname'  => customer.lastname,
                                                           })

      expect(gql.result.data['liveUsers'].last['apps'].first).to include('editing' => false)
    end

    it 'receives taskbar updates' do
      update_taskbar_item(live_user_entry_customer, { editing: true }, customer.id)

      result = mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'ticketLiveUserUpdates', 'liveUsers')
      expect(result.size).to eq(2)

      expect(result.first).to include('user' => {
                                        'firstname' => agent.firstname,
                                        'lastname'  => agent.lastname,
                                      })

      expect(result.last).to include('user' => {
                                       'firstname' => customer.firstname,
                                       'lastname'  => customer.lastname,
                                     })

      expect(result.last['apps'].first).to include('editing' => true)
    end

    context 'with multiple viewers' do
      let(:third_agent)                 { create(:agent) }
      let(:live_user_entry_third_agent) { create(:taskbar, key: "Ticket-#{ticket.id}", user_id: third_agent.id, app: 'mobile', state: { editing: false }) }

      it 'receives taskbar updates for all viewers' do
        update_taskbar_item(live_user_entry_customer, { editing: true }, customer.id)

        result = mock_channel.mock_broadcasted_messages.last.dig(:result, 'data', 'ticketLiveUserUpdates', 'liveUsers')
        expect(result.size).to eq(2)

        UserInfo.current_user_id = third_agent.id
        live_user_entry_third_agent
        UserInfo.current_user_id = agent.id

        update_taskbar_item(live_user_entry_third_agent, { editing: true }, third_agent.id)

        result = mock_channel.mock_broadcasted_messages.last.dig(:result, 'data', 'ticketLiveUserUpdates', 'liveUsers')
        expect(result.size).to eq(3)

        expect(result.first).to include('user' => {
                                          'firstname' => agent.firstname,
                                          'lastname'  => agent.lastname,
                                        })

        expect(result[1]).to include('user' => {
                                       'firstname' => customer.firstname,
                                       'lastname'  => customer.lastname,
                                     })

        expect(result.last).to include('user' => {
                                         'firstname' => third_agent.firstname,
                                         'lastname'  => third_agent.lastname,
                                       })
      end
    end
  end

  context 'when a customer', authenticated_as: :customer do
    it 'can not use subscription wihtout agent permission' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end
end
