# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'GraphQL Ticket Update - Group Restriction', :aggregate_failures, type: :graphql do # rubocop:disable RSpec/DescribeClass
  let(:agent)       { create(:agent, groups: [Group.find_by(name: 'Users'), other_group]) }
  let(:customer)    { create(:customer) }
  let(:ticket)      { create(:ticket, group: agent.groups.first, customer:) }
  let(:other_group) { create(:group) }

  describe 'TicketUpdate Mutation - Group field handling for customers' do
    let(:query) do
      <<~QUERY
        mutation ticketUpdate($ticketId: ID!, $input: TicketUpdateInput!, $meta: TicketUpdateMetaInput) {
          ticketUpdate(ticketId: $ticketId, input: $input, meta: $meta) {
            ticket {
              id
              group {
                id
                name
              }
            }
            errors {
              message
              field
            }
          }
        }
      QUERY
    end

    context 'when authenticated as customer', authenticated_as: :customer do
      it 'cannot change group_id via ticketUpdate mutation' do
        gql.execute(query, variables: {
                      ticketId: gql.id(ticket),
                      input:    {
                        title:   'Updated Title',
                        groupId: gql.id(other_group)
                      }
                    })

        ticket.reload
        expect(ticket.title).to eq('Updated Title')
        expect(ticket.group_id).to eq(agent.groups.first.id), 'Group should not change'
      end

      it 'silently ignores groupId argument without error' do
        gql.execute(query, variables: {
                      ticketId: gql.id(ticket),
                      input:    {
                        title:   'Updated Title',
                        groupId: gql.id(other_group)
                      }
                    })

        expect(ticket.reload.group_id).to eq(agent.groups.first.id)
        expect(gql.result.data[:ticket]).to be_present
        expect(gql.result.data[:errors]).to be_nil
      end
    end

    context 'when authenticated as agent', authenticated_as: :agent do
      it 'can change group_id via ticketUpdate mutation' do
        gql.execute(query, variables: {
                      ticketId: gql.id(ticket),
                      input:    {
                        title:   'Agent Updated',
                        groupId: gql.id(other_group)
                      }
                    })

        ticket.reload
        expect(ticket.title).to eq('Agent Updated')
        expect(ticket.group_id).to eq(other_group.id), 'Agent should be able to change group'
      end

      it 'can change group_id alone' do
        gql.execute(query, variables: {
                      ticketId: gql.id(ticket),
                      input:    {
                        groupId: gql.id(other_group)
                      }
                    })

        expect(ticket.reload.group_id).to eq(other_group.id)
      end
    end
  end
end
