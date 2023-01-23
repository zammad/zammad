# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Update, :aggregate_failures, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation ticketUpdate($ticketId: ID!, $input: TicketUpdateInput!) {
        ticketUpdate(ticketId: $ticketId, input: $input) {
          ticket {
            id
            title
            group {
              name
            }
            priority {
              name
            }
            customer {
              fullname
            }
            owner {
              fullname
            }
            objectAttributeValues {
              attribute {
                name
              }
              value
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
  let(:agent)           { create(:agent, groups: [ Group.find_by(name: 'Users')]) }
  let(:customer)        { create(:customer) }
  let(:user)            { agent }
  let(:group)           { agent.groups.first }
  let(:priority)        { Ticket::Priority.last }
  let(:ticket)          { create(:ticket, group: agent.groups.first, customer: customer) }
  let(:article_payload) { nil }

  let(:input_base_payload) do
    {
      title:      'Ticket Create Mutation Test',
      groupId:    gql.id(group),
      priorityId: gql.id(priority),
      customerId: gql.id(customer),
      ownerId:    gql.id(agent),
      article:    article_payload
      # pending_time: 10.minutes.from_now,
      # type: ...
    }
  end

  let(:input_payload) { input_base_payload }
  let(:variables)     { { ticketId: gql.id(ticket), input: input_payload } }

  let(:expected_base_response) do
    {
      'id'                    => gql.id(Ticket.last),
      'title'                 => 'Ticket Create Mutation Test',
      'owner'                 => { 'fullname' => agent.fullname },
      'group'                 => { 'name' => agent.groups.first.name },
      'customer'              => { 'fullname' => customer.fullname },
      'priority'              => { 'name' => Ticket::Priority.last.name },
      'objectAttributeValues' => [],
    }
  end

  let(:expected_response) do
    expected_base_response
  end

  context 'when updating a ticket' do

    context 'with an agent', authenticated_as: :agent do

      it 'updates the attributes' do
        gql.execute(query, variables: variables)
        expect(gql.result.data['ticket']).to eq(expected_response)
      end

      context 'without title' do
        let(:input_payload) { input_base_payload.tap { |h| h[:title] = '   ' } }

        it 'fails validation' do
          gql.execute(query, variables: variables)
          expect(gql.result.error_message).to include('Variable $input of type TicketUpdateInput! was provided invalid value for title')
        end
      end

      context 'with an article payload' do
        let(:article_payload) do
          {
            body: 'dummy',
            type: 'note',
          }
        end

        it 'adds a new article with a specific type' do
          expect { gql.execute(query, variables: variables) }
            .to change(Ticket::Article, :count).by(1)

          expect(Ticket.last.articles.last.type.name).to eq('note')
        end
      end

      context 'with custom object_attribute', db_strategy: :reset do
        let(:object_attribute) do
          screens = { create: { 'admin.organization': { shown: true, required: false } } }
          create(:object_manager_attribute_text, object_name: 'Ticket', screens: screens).tap do |_oa|
            ObjectManager::Attribute.migration_execute
          end
        end
        let(:input_payload) do
          input_base_payload.merge(
            {
              objectAttributeValues: [ { name: object_attribute.name, value: 'object_attribute_value' } ]
            }
          )
        end
        let(:expected_response) do
          expected_base_response.merge(
            {
              'objectAttributeValues' => [{ 'attribute' => { 'name'=>object_attribute.name }, 'value' => 'object_attribute_value' }]
            }
          )
        end

        it 'updates the attributes' do
          gql.execute(query, variables: variables)
          expect(gql.result.data['ticket']).to eq(expected_response)
        end
      end

      context 'with no permission to the group' do
        let(:group) { create(:group) }

        it 'raises an error', :aggregate_failures do
          gql.execute(query, variables: variables)
          expect(gql.result.error_type).to eq(GraphQL::ExecutionError)
          expect(gql.result.error_message).to eq('Access forbidden by Gql::Types::GroupType')
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      let(:input_payload) { input_base_payload.tap { |h| h.delete(:customerId) } }

      let(:expected_response) do
        expected_base_response.merge(
          {
            'owner'    => { 'fullname' => nil },
            'priority' => { 'name' => Ticket::Priority.where(default_create: true).first.name },
          }
        )
      end

      it 'updates the ticket with filtered values' do
        gql.execute(query, variables: variables)
        expect(gql.result.data['ticket']).to eq(expected_response)
      end

      context 'when sending a different customerId' do
        let(:input_payload) { input_base_payload.tap { |h| h[:customerId] = create(:customer).id } }

        it 'overrides the customerId' do
          gql.execute(query, variables: variables)
          expect(gql.result.data['ticket']).to eq(expected_response)
        end
      end
    end
  end
end
