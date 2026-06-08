# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::TaskbarItem::Add, :aggregate_failures, type: :graphql do
  context 'when adding a taskbar item for an user' do
    let(:mutation) do
      <<~MUTATION
        mutation userCurrentTaskbarItemAdd($input: UserTaskbarItemInput!) {
          userCurrentTaskbarItemAdd(input: $input) {
            taskbarItem {
              id
              key
            }
            errors {
              message
            }
          }
        }
      MUTATION
    end
    let(:input) do
      {
        key:,
        callback: 'TicketZoom',
        params:,
        prio:     1,
        notify:   false,
        app:      'desktop'
      }
    end

    let(:key)    { 'key' }
    let(:params) { {} }

    def execute_graphql_mutation
      gql.execute(mutation, variables: { input: input })
    end

    context 'when user is not authenticated' do
      it 'returns an error' do
        execute_graphql_mutation

        expect(gql.result.error_message).to eq('Authentication required')
      end
    end

    context 'when user is authenticated', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      context 'when taskbar item has no related object' do
        it 'adds a taskbar item' do
          expect { execute_graphql_mutation }.to change(Taskbar, :count).by(1)
        end

        it 'does not call mark as seen service' do
          allow(OnlineNotification).to receive(:mark_as_seen!)
          execute_graphql_mutation
          expect(OnlineNotification).not_to have_received(:mark_as_seen!)
        end
      end

      context 'when taskbar item has a related object' do
        let(:ticket) { create(:ticket) }
        let(:key)    { "Ticket-#{ticket.id}" }
        let(:params) { { ticket_id: ticket.id } }

        before do
          agent.groups << ticket.group
        end

        it 'adds a taskbar item' do
          expect { execute_graphql_mutation }.to change(Taskbar, :count).by(1)
        end

        it 'marks the related object as seen' do
          allow(OnlineNotification).to receive(:mark_as_seen!)

          execute_graphql_mutation

          expect(OnlineNotification).to have_received(:mark_as_seen!).with(ticket, agent)
        end
      end
    end
  end
end
