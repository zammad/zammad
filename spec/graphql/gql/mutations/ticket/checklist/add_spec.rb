# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Checklist::Add, current_user_id: 1, type: :graphql do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, group: group) }

  let(:query) do
    <<~QUERY
      mutation ticketChecklistAdd($ticketId: ID!, $templateId: ID) {
        ticketChecklistAdd(ticketId: $ticketId, templateId: $templateId) {
          checklist {
            id
            name
            items {
              id
              text
              checked
            }
          }
          errors {
            message
          }
        }
      }
    QUERY
  end

  let(:variables) { { ticketId: gql.id(ticket) } }

  let(:response) do
    {
      'id'    => a_kind_of(String),
      'name'  => '',
      'items' => include(
        include(
          'id'      => a_kind_of(String),
          'text'    => '',
          'checked' => false,
        )
      ),
    }
  end

  before do
    setup if defined?(setup)
    checklist if defined?(checklist)
    gql.execute(query, variables: variables)
  end

  shared_examples 'creating the ticket checklist' do
    it 'creates the ticket checklist' do
      expect(gql.result.data[:checklist]).to include(response)
    end
  end

  shared_examples 'raising an error' do |error_type|
    it 'raises an error' do
      expect(gql.result.error_type).to eq(error_type)
    end
  end

  shared_examples 'returning an error message' do |error_message|
    it 'returns an error message' do
      expect(gql.result.data[:errors]).to include('message' => error_message)
    end
  end

  context 'with authenticated session', authenticated_as: :agent do
    it_behaves_like 'creating the ticket checklist'

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

    context 'when ticket checklist already exists' do
      let(:checklist) { create(:checklist, ticket: ticket) }

      it_behaves_like 'returning an error message', 'This ticket already has a checklist.'
    end

    context 'when creating from a checklist template' do
      let(:template)  { create(:checklist_template) }
      let(:variables) { { ticketId: gql.id(ticket), templateId: gql.id(template) } }

      let(:response) do
        {
          'id'    => a_kind_of(String),
          'name'  => template.name,
          'items' => include(
            include(
              'text'    => satisfy { |text| template.items.pluck(:text).include? text },
              'checked' => false,
            ),
          ),
        }
      end

      before { template }

      it_behaves_like 'creating the ticket checklist'

      context 'with ticket read permission' do
        let(:agent) { create(:agent, groups: [group], group_names_access_map: { group.name => 'read' }) }

        it_behaves_like 'raising an error', Pundit::NotAuthorizedError
      end

      context 'with ticket read+change permissions' do
        let(:agent) { create(:agent, groups: [group], group_names_access_map: { group.name => %w[read change] }) }

        it_behaves_like 'creating the ticket checklist'
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
