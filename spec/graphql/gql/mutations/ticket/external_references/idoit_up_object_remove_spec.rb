# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::ExternalReferences::IdoitUpObjectRemove, type: :graphql do
  let(:variables)                   { { ticketId: gql.id(ticket), idoitUpObjectId: idoit_up_object_id } }
  let(:ticket)                      { create(:ticket, preferences: { 'idoit_up' => { 'object_ids' => %w[00000000Test0042 00000000Test0026] } }) }
  let(:idoit_up_object_id)          { '00000000Test0026' }
  let(:idoit_up_integration_active) { true }

  let(:mutation) do
    <<~MUTATION
      mutation ticketExternalReferencesIdoitUpObjectRemove(
        $ticketId: ID!
        $idoitUpObjectId: String!
      ) {
        ticketExternalReferencesIdoitUpObjectRemove(
          ticketId: $ticketId
          idoitUpObjectId: $idoitUpObjectId
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
    Setting.set('idoit_up_integration', idoit_up_integration_active)
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    context 'when i-doit up integration is inactive' do
      let(:idoit_up_integration_active) { false }

      it 'raises an error' do
        gql.execute(mutation, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when ticket is used' do
      context 'when an agent has access to the ticket' do
        let(:agent) { create(:agent, groups: [ticket.group]) }

        it 'removes the i-doit up object' do
          gql.execute(mutation, variables: variables)

          expect(ticket.reload.preferences).to include(idoit_up: { object_ids: ['00000000Test0042'] })
        end

        context 'when i-doit up objects are stored as strings (legacy app)' do
          let(:ticket) { create(:ticket, preferences: { 'idoit_up' => { 'object_ids' => %w[00000000Test0042 00000000Test0026] } }) }

          it 'removes the i-doit up object' do
            gql.execute(mutation, variables: variables)

            expect(ticket.reload.preferences).to include(idoit_up: { object_ids: ['00000000Test0042'] })
          end
        end
      end

      context 'when an agent has no access to the ticket' do
        before { gql.execute(mutation, variables:) }

        it_behaves_like 'graphql responds with forbidden'
      end
    end
  end

  context 'when unauthenticated' do
    before { gql.execute(mutation, variables:) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
