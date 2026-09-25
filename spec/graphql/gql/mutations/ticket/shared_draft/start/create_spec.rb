# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::SharedDraft::Start::Create, type: :graphql do
  let(:group)    { create(:group) }
  let(:content)  { { content: Faker::Lorem.unique.sentence } }
  let(:name)     { Faker::Lorem.unique.sentence }
  let(:form_id)  { '123' }

  let(:variables) do
    {
      name:,
      input: {
        content:,
        formId:  form_id,
        groupId: gql.id(group),
      }
    }
  end

  let(:query) do
    <<~QUERY
      mutation ticketSharedDraftStartCreate($name: String!, $input: TicketSharedDraftStartInput!) {
        ticketSharedDraftStartCreate(name: $name, input: $input) {
          sharedDraft {
            id
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) do
      create(:agent)
        .tap { |elem| elem.user_groups.create!(group:, access: :create) }
    end

    context 'when agent has access to the draft group' do
      let(:draft) do
        Gql::ZammadSchema.verified_object_from_id(
          gql.result.data.dig('sharedDraft', 'id'),
          type: Ticket::SharedDraftStart
        )
      end

      it 'returns new object' do
        gql.execute(query, variables:)

        expect(draft).to have_attributes(name:, content:, group:)
      end

      # The old UI stores a customer id as a string, so the typed-in value of a customer who does
      #   not exist yet is marked apart here, before the draft is stored.
      context 'with a customer who does not exist yet' do
        let(:content) { { 'customer_id' => '123456' } }

        it 'stores the typed-in number wrapped' do
          gql.execute(query, variables:)

          expect(draft.content).to include('customer_id' => { 'phone' => '123456' })
        end
      end

      context 'with a known customer' do
        let(:content) { { 'customer_id' => 2 } }

        it 'stores the id as it is' do
          gql.execute(query, variables:)

          expect(draft.content).to include('customer_id' => 2)
        end
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated' do
    before do
      gql.execute(query, variables:)
    end
  end
end
