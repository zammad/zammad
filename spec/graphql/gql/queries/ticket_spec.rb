# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket, current_user_id: 1, type: :graphql do

  context 'when fetching tickets' do
    let(:agent)     { create(:agent) }
    let(:query)     do
      <<~QUERY
        query ticket($ticketId: ID, $ticketInternalId: Int, $ticketNumber: String) {
          ticket(
            ticket: {
              ticketId: $ticketId
              ticketInternalId: $ticketInternalId
              ticketNumber: $ticketNumber
            }
          ) {
            id
            internalId
            number
            title
            owner {
              id
              firstname
              email
              createdBy {
                internalId
              }
              updatedBy {
                internalId
              }
            }
            customer {
              id
              firstname
              email
            }
            organization {
              name
            }
            tags
            subscribed
            mentions(first: 20) {
              edges {
                node {
                  user {
                    id
                  }
                  userTicketAccess {
                    agentReadAccess
                  }
                }
                cursor
              }
            }
            policy {
              update
              destroy
              followUp
              agentReadAccess
              agentUpdateAccess
              createMentions
            }
            timeUnitsPerType {
              name
              timeUnit
            }
            stateColorCode
            checklist {
              name
            }
            referencingChecklistTickets {
              id
            }
            #{additional_query_fields}
          }
        }
      QUERY
    end
    let(:additional_query_fields) { '' }
    let(:variables) { { ticketId: gql.id(ticket) } }
    let(:ticket) do
      create(:ticket).tap do |t|
        t.tag_add('tag1', 1)
        t.tag_add('tag2', 1)

      end
    end
    let!(:checklist) do
      create(:checklist, ticket: ticket, item_count: 1, created_by: agent, updated_by: agent).tap do |checklist|
        checklist.items.last.update!(text: "Ticket##{another_ticket.number}", ticket_id: another_ticket.id)
        checklist.reload
      end
    end
    let!(:another_ticket) do
      create(:ticket, group: ticket.group, state: Ticket::State.find_by(name: 'new')).tap do |t|
        create(:checklist, ticket: t, item_count: 1, created_by: agent, updated_by: agent).tap do |checklist|
          checklist.items.last.update!(text: "Ticket##{ticket.number}", ticket_id: ticket.id)
          checklist.reload
        end
      end
    end

    before do
      setup if defined?(setup)
      gql.execute(query, variables: variables)
    end

    context 'with an agent', authenticated_as: :agent do
      context 'with permission' do
        let(:agent) { create(:agent, groups: [ticket.group]) }
        let(:base_expected_result) do
          {
            'id'                          => gql.id(ticket),
            'internalId'                  => ticket.id,
            'number'                      => ticket.number,
            # Agent is allowed to see user data
            'owner'                       => include(
              'firstname' => ticket.owner.firstname,
              'email'     => ticket.owner.email,
              'createdBy' => { 'internalId' => 1 },
              'updatedBy' => { 'internalId' => 1 },
            ),
            'tags'                        => %w[tag1 tag2],
            'policy'                      => {
              'agentReadAccess'   => true,
              'agentUpdateAccess' => true,
              'createMentions'    => true,
              'destroy'           => false,
              'followUp'          => true,
              'update'            => true
            },
            'stateColorCode'              => 'open',
            'checklist'                   => {
              'name' => checklist.name
            },
            'referencingChecklistTickets' => [
              {
                'id' => gql.id(another_ticket)
              }
            ]
          }
        end
        let(:expected_result) { base_expected_result }

        shared_examples 'finds the ticket' do
          it 'finds the ticket' do
            expect(gql.result.data).to include(expected_result)
          end
        end

        context 'when fetching a ticket by ticketId' do
          include_examples 'finds the ticket'
        end

        context 'when fetching a ticket by ticketInternalId' do
          let(:variables) { { ticketInternalId: ticket.id } }

          include_examples 'finds the ticket'
        end

        context 'when fetching a ticket by ticketNumber' do
          let(:variables) { { ticketNumber: ticket.number } }

          include_examples 'finds the ticket'
        end

        context 'when locator is missing' do
          let(:variables) { {} }

          it 'raises an exception' do
            expect(gql.result.error_type).to eq(GraphQL::Schema::Validator::ValidationFailedError)
          end
        end

        context 'with having checklist feature disabled' do
          let(:setup) do
            Setting.set('checklist', false)
          end
          let(:expected_result) { base_expected_result.merge({ 'checklist' => nil, 'referencingChecklistTickets' => nil }) }

          include_examples 'finds the ticket'
        end

        context 'with having time accounting enabled' do
          let(:ticket_time_accounting_types)      { create_list(:ticket_time_accounting_type, 2) }
          let(:ticket_time_accounting)            { create(:ticket_time_accounting, ticket: ticket, time_unit: 50) }
          let(:ticket_time_accounting_with_type)  { create(:ticket_time_accounting, ticket: ticket, time_unit: 25, type: ticket_time_accounting_types[0]) }
          let(:ticket_time_accounting_with_type2) { create(:ticket_time_accounting, ticket: ticket, time_unit: 250, type: ticket_time_accounting_types[1]) }

          let(:setup) do
            Setting.set('time_accounting', true)
            Setting.set('time_accounting_types', true)

            ticket_time_accounting_with_type2 && ticket_time_accounting_with_type && ticket_time_accounting
          end

          it 'contains time unit entries grouped by type with a sum' do
            expect(gql.result.data[:timeUnitsPerType]).to eq([
                                                               {
                                                                 'name'     => ticket_time_accounting_types[1].name,
                                                                 'timeUnit' => 250.0,
                                                               },
                                                               {
                                                                 'name'     => 'None',
                                                                 'timeUnit' => 50.0,
                                                               },
                                                               {
                                                                 'name'     => ticket_time_accounting_types[0].name,
                                                                 'timeUnit' => 25.0,
                                                               },
                                                             ])
          end
        end

        context 'when subscribed' do
          let(:other_user) { create(:agent, groups: [ticket.group]) }

          before do
            Mention.subscribe! ticket, agent
            Mention.subscribe! ticket, other_user
            other_user.update(active: false)
            gql.execute(query, variables: variables)
          end

          it 'returns subscribed' do
            expect(gql.result.data).to include('subscribed' => true)
          end

          it 'returns user and access information in subscribers list' do
            expect(gql.result.data.dig('mentions', 'edges'))
              .to include(include('node' => include('user' => include('id' => gql.id(agent)), 'userTicketAccess' => { 'agentReadAccess' => true })))
          end

          it 'does not return inactive users' do
            expect(gql.result.data.dig('mentions', 'edges').count).to be(1)
          end
        end

        context 'with usage of issue tracker references' do
          let(:ticket) do
            Setting.set('github_integration', true)

            create(:ticket, preferences: { 'github' => { 'issue_links' => ['https://github.com/example/example/issues/1234'] } })
          end

          let(:additional_query_fields) do
            <<~ADDITIONALFIELDS
              externalReferences {
                github
                gitlab
              }
            ADDITIONALFIELDS
          end

          it 'contains issue tracker references' do
            expect(gql.result.data).to include(
              'externalReferences' => include({
                                                'github' => ['https://github.com/example/example/issues/1234'],
                                                'gitlab' => nil
                                              })
            )
          end
        end
      end

      context 'without permission' do
        it 'raises authorization error' do
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        end
      end

      context 'without ticket' do
        let(:ticket)         { create(:ticket).tap(&:destroy) }
        let(:checklist)      { nil }
        let(:another_ticket) { nil }

        it 'fetches no ticket' do
          expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      let(:customer) { create(:customer) }
      let(:ticket)   { create(:ticket, customer: customer) }
      let(:expected_result) do
        {
          'id'                          => gql.id(ticket),
          'internalId'                  => ticket.id,
          'number'                      => ticket.number,
          # Customer is not allowed to see data of other users
          'owner'                       => include(
            'firstname' => ticket.owner.firstname,
            'email'     => nil,
            'createdBy' => nil,
            'updatedBy' => nil,
          ),
          # Customer may see their own data
          'customer'                    => include(
            'firstname' => customer.firstname,
            'email'     => customer.email,
          ),
          'policy'                      => {
            'agentReadAccess'   => false,
            'agentUpdateAccess' => false,
            'createMentions'    => false,
            'destroy'           => false,
            'followUp'          => true,
            'update'            => true
          },
          'checklist'                   => nil,
          'referencingChecklistTickets' => nil,
        }
      end

      it 'finds the ticket, but without data of other users' do
        expect(gql.result.data).to include(expected_result)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
