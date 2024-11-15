# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::History, timezone: 'Europe/Berlin', type: :graphql do
  context 'when fetching history of a ticket' do
    let(:group)  { create(:group) }
    let(:owner)  { create(:user) }
    let(:ticket) { create(:ticket, group:, owner:, created_by: owner) }

    let(:variables) { { ticketId: gql.id(ticket) } }

    let(:query) do
      <<~QUERY
        query ticketHistory($ticketId: ID, $ticketInternalId: Int, $ticketNumber: String) {
          ticketHistory(
            ticket: {
              ticketId: $ticketId
              ticketInternalId: $ticketInternalId
              ticketNumber: $ticketNumber
            }
          ) {
            createdAt
            records {
              issuer {
                ... on User {
                  fullname
                }
                ... on Trigger {
                  id
                  internalId
                  name
                }
                ... on Job {
                  id
                  internalId
                  name
                }
                ... on PostmasterFilter {
                  id
                  internalId
                  name
                }
                ... on ObjectClass {
                  klass
                  info
                }
              }
              events {
                createdAt
                action
                object {
                  ... on Ticket {
                    title
                  }
                  ... on TicketArticle {
                    body
                  }
                  ... on ObjectClass {
                    klass
                    info
                  }
                }
                attribute
                changes
              }
            }
          }
        }
      QUERY
    end

    before do
      Time.use_zone('UTC') do
        freeze_time

        travel_to(2.days.ago) do
          ticket
          ticket.update!(title: 'New title', updated_by: create(:agent))
        end

        travel_to(1.day.ago) do
          ticket.update!(title: 'Another title', updated_by: create(:agent))
        end
      end
      gql.execute(query, variables:)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'

    context 'with authenticated session', authenticated_as: :authenticated do
      context 'when user has no access to ticket' do
        let(:authenticated) { create(:agent) }

        it 'raises an error' do
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        end
      end

      context 'when user has access to ticket' do
        let(:authenticated) { create(:agent, groups: [group]) }

        it 'returns grouped history records' do
          expect(gql.result.data).to be_present
        end
      end
    end
  end
end
