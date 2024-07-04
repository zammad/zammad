# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::SharedDraft::Start::Delete, :aggregate_failures, type: :graphql do
  let(:group)        { create(:group) }
  let(:shared_draft) { create(:ticket_shared_draft_start, group:) }
  let(:variables)    { { sharedDraftId: gql.id(shared_draft) } }

  let(:query) do
    <<~QUERY
      mutation ticketSharedDraftStartDelete($sharedDraftId: ID!) {
        ticketSharedDraftStartDelete(sharedDraftId: $sharedDraftId) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  context 'with an agent', authenticated_as: :agent do
    let(:access) { :create }

    let(:agent) do
      create(:agent)
        .tap { |elem| elem.user_groups.create!(group:, access:) if access }
    end

    context 'when agent has access to the draft group' do
      it 'deletes the shared draft' do
        expect { gql.execute(query, variables:) }
          .to change { Ticket::SharedDraftStart.exists? shared_draft.id }
          .to false
      end

      it 'returns success' do
        gql.execute(query, variables:)
        expect(gql.result.data).to include('success' => true)
      end
    end

    context 'when agent has insufficient access to the given group' do
      let(:access) { 'read' }

      it 'does not delete the shared draft' do
        expect { gql.execute(query, variables:) }
          .not_to change { Ticket::SharedDraftStart.exists? shared_draft.id }
          .from true
      end

      it 'raises an error' do
        gql.execute(query, variables:)

        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when agent has no access to the given group' do
      let(:access) { false }

      it 'does not delete the shared draft' do
        expect { gql.execute(query, variables:) }
          .not_to change { Ticket::SharedDraftStart.exists? shared_draft.id }
          .from true
      end

      it 'raises an error' do
        gql.execute(query, variables:)

        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated' do
    before do
      gql.execute(query, variables:)
    end
  end
end
