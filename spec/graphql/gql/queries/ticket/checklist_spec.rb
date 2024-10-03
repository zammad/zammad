# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::Checklist, current_user_id: 1, type: :graphql do
  let(:group)     { create(:group) }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:ticket)    { create(:ticket, group: group) }
  let(:checklist) { create(:checklist, name: 'foobar', ticket: ticket) }

  let(:query) do
    <<~QUERY
      query ticketChecklist($ticketId: ID, $ticketInternalId: Int, $ticketNumber: String) {
        ticketChecklist(
          ticket: {
            ticketId: $ticketId
            ticketInternalId: $ticketInternalId
            ticketNumber: $ticketNumber
          }
        ) {
          id
          name
          completed
          incomplete
          complete
          total
          items {
            id
            text
            checked
            ticketReference {
              ticket {
                id
              }
            }
          }
        }
      }
    QUERY
  end

  let(:variables) { { ticketId: gql.id(ticket) } }

  let(:response) do
    {
      'id'         => gql.id(checklist),
      'name'       => checklist.name,
      'completed'  => false,
      'incomplete' => 5,
      'complete'   => 0,
      'total'      => 5,
      'items'      => checklist.items.sort_by(&:id).map do |item|
        {
          'id'              => gql.id(item),
          'text'            => item.text,
          'checked'         => item.checked,
          'ticketReference' => nil,
        }
      end,
    }
  end

  before do
    setup if defined?(setup)
    checklist
    gql.execute(query, variables: variables)
  end

  shared_examples 'returning checklist data' do
    it 'returns checklist data' do
      expect(gql.result.data).to eq(response)
    end
  end

  shared_examples 'raising an error' do |error_type|
    it 'raises an error' do
      expect(gql.result.error_type).to eq(error_type)
    end
  end

  context 'with authenticated session', authenticated_as: :agent do
    it_behaves_like 'returning checklist data'

    context 'with disabled checklist feature' do
      let(:setup) do
        Setting.set('checklist', false)
      end

      it_behaves_like 'raising an error', Exceptions::Forbidden
    end

    context 'without access to the ticket' do
      let(:agent) { create(:agent) }

      it_behaves_like 'raising an error', Exceptions::Forbidden
    end

    context 'with ticket read permission' do
      let(:agent) { create(:agent, groups: [group], group_names_access_map: { group.name => 'read' }) }

      it_behaves_like 'returning checklist data'
    end

    context 'when checklist does not exist' do
      let(:checklist) { nil }
      let(:response)  { nil }

      it_behaves_like 'returning checklist data'
    end

    context 'with alternative input variables' do
      context 'with internal ticket ID' do
        let(:variables) { { ticketInternalId: ticket.id } }

        it_behaves_like 'returning checklist data'
      end

      context 'with ticket number' do
        let(:variables) { { ticketNumber: ticket.number } }

        it_behaves_like 'returning checklist data'
      end

      context 'without any of required variables' do
        let(:variables) { {} }

        it_behaves_like 'raising an error', GraphQL::Schema::Validator::ValidationFailedError
      end
    end

    context 'with ticket checklist item' do
      let(:checklist) do
        create(:checklist, name: 'foobar', ticket: ticket, item_count: 1).tap do |checklist|
          checklist.items.last.update!(text: "Ticket##{another_ticket.number}", ticket_id: another_ticket.id)
          checklist.reload
        end
      end

      context 'with an open ticket' do
        let(:another_ticket) { create(:ticket, group: group, state: Ticket::State.find_by(name: 'open')) }

        let(:response) do
          {
            'id'         => gql.id(checklist),
            'name'       => checklist.name,
            'completed'  => false,
            'incomplete' => 1,
            'complete'   => 0,
            'total'      => 1,
            'items'      => [
              {
                'id'              => gql.id(checklist.items.last),
                'text'            => checklist.items.last.text,
                'checked'         => checklist.items.last.checked,
                'ticketReference' => {
                  'ticket' => {
                    'id' => gql.id(another_ticket),
                  },
                },
              },
            ],
          }
        end

        it_behaves_like 'returning checklist data'
      end

      context 'with a closed ticket' do
        let(:another_ticket) { create(:ticket, group: group, state: Ticket::State.find_by(name: 'closed')) }

        let(:response) do
          {
            'id'         => gql.id(checklist),
            'name'       => checklist.name,
            'completed'  => true,
            'incomplete' => 0,
            'complete'   => 1,
            'total'      => 1,
            'items'      => [
              {
                'id'              => gql.id(checklist.items.last),
                'text'            => checklist.items.last.text,
                'checked'         => checklist.items.last.checked,
                'ticketReference' => {
                  'ticket' => {
                    'id' => gql.id(another_ticket),
                  },
                },
              },
            ],
          }
        end

        it_behaves_like 'returning checklist data'
      end

      context 'when the agent has no access to the linked ticket' do
        let(:another_ticket) do
          create(:ticket, state: Ticket::State.find_by(name: 'new')).tap do |t|
            create(:checklist, name: 'foobar', ticket: t, item_count: 1).tap do |checklist|
              checklist.items.last.update!(text: "Ticket##{ticket.number}", ticket_id: ticket.id)
              checklist.reload
            end
          end
        end

        let(:response) do
          {
            'id'         => gql.id(checklist),
            'name'       => checklist.name,
            'completed'  => false,
            'incomplete' => 1,
            'complete'   => 0,
            'total'      => 1,
            'items'      => [
              {
                'id'              => gql.id(checklist.items.last),
                'text'            => checklist.items.last.text,
                'checked'         => checklist.items.last.checked,
                'ticketReference' => {
                  'ticket' => nil,
                },
              },
            ],
          }
        end

        it_behaves_like 'returning checklist data'
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
