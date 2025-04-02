# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::SharedDraft::Start::Update, type: :graphql do
  let(:group)        { create(:group) }
  let(:new_group)    { group }
  let(:shared_draft) { create(:ticket_shared_draft_start, group:) }
  let(:new_content)  { { content: 'updated' } }
  let(:form_id)      { '123' }

  let(:variables)    do
    {
      sharedDraftId: gql.id(shared_draft),
      input:         {
        formId:  form_id,
        groupId: gql.id(new_group),
        content: new_content
      }
    }
  end

  let(:query) do
    <<~QUERY
      mutation ticketSharedDraftStartUpdate($input: TicketSharedDraftStartInput!, $sharedDraftId: ID!) {
        ticketSharedDraftStartUpdate(input: $input, sharedDraftId: $sharedDraftId) {
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
    let(:access) { :create }

    let(:agent) do
      create(:agent)
        .tap { |elem| elem.user_groups.create!(group:, access:) if access }
    end

    context 'when agent has access to the draft group' do
      it 'updates the shared draft' do
        gql.execute(query, variables:)
        expect(shared_draft.reload)
          .to have_attributes(group:, content: new_content)
      end

      it 'returns itself' do
        gql.execute(query, variables:)
        expect(gql.result.data)
          .to include('sharedDraft' => include('id' => gql.id(shared_draft)))
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated' do
    before do
      gql.execute(query, variables:)
    end
  end
end
