# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Update::Bulk, :aggregate_failures, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation ticketUpdateBulk($ticketIds: [ID!]!, $input: TicketUpdateInput!, $macroId: ID) {
        ticketUpdateBulk(ticketIds: $ticketIds, input: $input, macroId: $macroId) {
          success
          errors {
            failedTicket {
              id
            }
            errorType
            message
          }
        }
      }
    QUERY
  end
  let(:agent)           { create(:agent, groups: [ Group.find_by(name: 'Users')]) }
  let(:customer)        { create(:customer) }
  let(:user)            { agent }
  let(:group)           { agent.groups.first }
  let(:ticket1)         { create(:ticket, title: 'Ticket 1', group: agent.groups.first, customer: customer) }
  let(:ticket2)         { create(:ticket, title: 'Ticket 2', group: agent.groups.first, customer: customer) }
  let(:input_payload)   { { title: 'Ticket Bulk Update Mutation Test' } }

  let(:variables) { { ticketIds: [gql.id(ticket1), gql.id(ticket2)], input: input_payload } }

  let(:expected_response) do
    { success: true, errors: nil }.with_indifferent_access
  end

  context 'when updating a ticket' do

    context 'with an agent', authenticated_as: :agent do

      it 'updates the attributes' do
        gql.execute(query, variables: variables)
        expect(gql.result.data).to eq(expected_response)
        expect(ticket1.reload).to have_attributes(title: 'Ticket Bulk Update Mutation Test')
      end

      context 'when a ticket update fails' do
        before do
          allow_any_instance_of(Service::Ticket::Update).to receive(:execute).and_wrap_original do |m, *args, **kwargs|
            if kwargs[:ticket].title == 'Ticket 2'
              raise ActiveRecord::RecordNotSaved.new('test failure during update of second ticket', ticket2)
            end

            m.call(*args, **kwargs)
          end
        end

        let(:expected_response) do
          {
            success: nil,
            errors:  [
              {
                failedTicket: { id: gql.id(ticket2) },
                message:      'test failure during update of second ticket',
                errorType:    ActiveRecord::RecordNotSaved.to_s,
              },
            ],
          }.with_indifferent_access
        end

        it 'rolls back the entire transaction' do
          gql.execute(query, variables: variables)
          expect(gql.result.data).to eq(expected_response)
          expect(ticket1.reload).to have_attributes(title: 'Ticket 1')
        end
      end

      context 'with a macro' do
        let(:new_title) { Faker::Lorem.word }
        let(:macro)     { create(:macro, perform: { 'ticket.title' => { 'value' => new_title } }) }

        let(:variables) do
          {
            ticketIds: [gql.id(ticket1), gql.id(ticket2)],
            input:     input_payload,
            macroId:   gql.id(macro)
          }
        end

        it 'applies the macro' do
          gql.execute(query, variables:)

          expect(ticket1.reload).to have_attributes(title: new_title)
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      it 'raises an error' do
        gql.execute(query, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
