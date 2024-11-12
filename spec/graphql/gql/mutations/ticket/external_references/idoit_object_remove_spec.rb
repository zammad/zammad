# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::ExternalReferences::IdoitObjectRemove, type: :graphql do
  let(:variables)                { { ticketId: gql.id(ticket), idoitObjectId: idoit_object_id } }
  let(:ticket)                   { create(:ticket, preferences: { 'idoit' => { 'object_ids' => [42, 26] } }) }
  let(:idoit_object_id)          { 26 }
  let(:idoit_integration_active) { true }

  let(:mutation) do
    <<~MUTATION
      mutation ticketExternalReferencesIdoitObjectRemove(
        $ticketId: ID!
        $idoitObjectId: Int!
      ) {
        ticketExternalReferencesIdoitObjectRemove(
          ticketId: $ticketId
          idoitObjectId: $idoitObjectId
        ) {
          success
          errors {
            message
            field
          }
        }
      }
    MUTATION
  end

  before do
    Setting.set('idoit_integration', idoit_integration_active)
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    context 'when idoit integration is inactive' do
      let(:idoit_integration_active) { false }

      it 'raises an error' do
        gql.execute(mutation, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when ticket is used' do
      context 'when an agent has access to the ticket' do
        let(:agent) { create(:agent, groups: [ticket.group]) }

        it 'removes the idoit object' do
          gql.execute(mutation, variables: variables)

          expect(ticket.reload.preferences).to include(idoit: { object_ids: [42] })
        end

        context 'when idoit objects are stored as strings (legacy app)' do
          let(:ticket) { create(:ticket, preferences: { 'idoit' => { 'object_ids' => %w[42 26] } }) }

          it 'removes the idoit object' do
            gql.execute(mutation, variables: variables)

            expect(ticket.reload.preferences).to include(idoit: { object_ids: [42] })
          end
        end
      end

      context 'when an agent has no access to the ticket' do
        before { gql.execute(mutation, variables:) }

        it_behaves_like 'graphql responds with error if unauthenticated'
      end
    end
  end

  context 'when unauthenticated' do
    before { gql.execute(mutation, variables:) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
