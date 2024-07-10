# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::Ticket::SharedDraftStartType, current_user_id: 1 do
  let(:instance) { described_class.send(:new, draft, nil) }

  context 'when draft body contains images', authenticated_as: :agent, type: :graphql do
    let(:shared_draft) { create(:ticket_shared_draft_start, :with_inline_image, group:) }
    let(:group)        { create(:group) }
    let(:agent)        { create(:agent, groups: [group]) }
    let(:variables)    { { sharedDraftId: gql.id(shared_draft) } }

    let(:query) do
      <<~QUERY
        query ticketSharedDraftStartSingle($sharedDraftId: ID!) {
          ticketSharedDraftStartSingle(sharedDraftId: $sharedDraftId) {
            id
            name
            content
          }
        }
      QUERY
    end

    before do
      gql.execute(query, variables: variables)
    end

    it 'returns image tags with URLs' do
      expect(gql.result.data)
        .to include('content' => include('body' => start_with('text and <img src="/api/v1/attachments')))
    end
  end
end
