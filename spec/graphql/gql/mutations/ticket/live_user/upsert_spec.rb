# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::LiveUser::Upsert, :aggregate_failures, type: :graphql do
  context 'when visiting a ticket as a user', authenticated_as: :agent do
    let(:agent)    { create(:agent, groups: [ticket.group]) }
    let(:customer) { create(:customer) }
    let(:ticket)   { create(:ticket, customer: customer) }
    let(:editing)  { false }

    let(:query) do
      <<~QUERY
        mutation ticketLiveUserUpsert($id: ID!, $app: EnumTaskbarApp!, $editing: Boolean!) {
          ticketLiveUserUpsert(id: $id, app: $app, editing: $editing) {
            success
            errors {
              message
              field
            }
          }
        }
      QUERY
    end

    let(:variables) do
      {
        id:      gql.id(ticket),
        app:     'mobile',
        editing: editing,
      }
    end

    before do
      freeze_time
      create(:taskbar, key: "Ticket-#{ticket.id}", user_id: customer.id, app: 'mobile')
    end

    context 'without own live user entry' do
      context 'without editing the ticket' do
        it 'adds the live user entry' do
          expect { gql.execute(query, variables: variables) }.to change(Taskbar, :count).by(1)
        end
      end

      context 'with editing the ticket' do
        let(:editing) { true }

        it 'adds the live user entry' do
          expect { gql.execute(query, variables: variables) }.to change(Taskbar, :count).by(1)
        end
      end
    end

    context 'with already existing live user entry for own user' do
      before do
        # Create already existing item.
        create(:taskbar, key: "Ticket-#{ticket.id}", user_id: agent.id, app: 'mobile')

        travel 30.minutes
      end

      context 'with editing the ticket' do
        let(:editing) { true }

        it 'updates the live user entry' do
          expect { gql.execute(query, variables: variables) }.not_to change(Taskbar, :count)
        end
      end
    end
  end
end
