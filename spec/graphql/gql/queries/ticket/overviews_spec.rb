# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::Overviews, type: :graphql do

  context 'when fetching ticket overviews' do
    let(:agent)     { create(:agent) }
    let(:query)     do
      <<~QUERY
        query ticketOverviews($withTicketCount: Boolean!) {
          ticketOverviews {
            edges {
              node {
                id
                name
                link
                prio
                orderBy
                orderDirection
                viewColumns {
                  key
                  value
                }
                orderColumns {
                  key
                  value
                }
                active
                ticketCount @include(if: $withTicketCount)
              }
            }
          }
        }
      QUERY
    end
    let(:variables) { { withTicketCount: false } }

    before do
      gql.execute(query, variables: variables)
    end

    context 'with an agent', authenticated_as: :agent do
      it 'has agent overview' do
        expect(gql.result.nodes.first).to include('name' => 'My Assigned Tickets', 'link' => 'my_assigned', 'prio' => 1000, 'active' => true,)
      end

      it 'has view and order columns' do
        expect(gql.result.nodes.first).to include(
          'viewColumns'  => include({ 'key' => 'title', 'value' => 'Title' }),
          'orderColumns' => include({ 'key' => 'created_at', 'value' => 'Created at' }),
        )
      end

      context 'with object attributes and unknown attributes', db_strategy: :reset do
        let(:oa) do
          create(:object_manager_attribute_text, :required_screen).tap do
            ObjectManager::Attribute.migration_execute
          end
        end
        # Change the overview to include an object attribute column and a column that has an unknown field.
        let(:overview) do
          Overview.find_by('link' => 'my_assigned').tap do |overview|
            overview.view = { 's' => [oa.name, 'unknown_field'] }
            overview.save!
          end
        end
        let(:variables) do
          overview
          { withTicketCount: false }
        end

        it 'lists view colummns correctly' do
          expect(gql.result.nodes.first).to include(
            'viewColumns' => [ { 'key' => oa.name, 'value' => oa.display }, { 'key' => 'unknown_field', 'value' => nil }],
          )
        end
      end

      context 'without ticket count' do
        it 'does not include ticketCount field' do
          expect(gql.result.nodes.first).not_to have_key('ticketCount')
        end
      end

      context 'with ticket count' do
        let(:variables) { { withTicketCount: true } }

        it 'includes ticketCount field' do
          expect(gql.result.nodes.first['ticketCount']).to eq(0)
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'has customer overview' do
        expect(gql.result.nodes.first).to include('name' => 'My Tickets', 'link' => 'my_tickets', 'prio' => 1100, 'active' => true,)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
