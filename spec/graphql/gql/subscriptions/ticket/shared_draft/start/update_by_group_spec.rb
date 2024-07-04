# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::Ticket::SharedDraft::Start::UpdateByGroup, type: :graphql do
  let(:subscription) do
    <<~QUERY
      subscription ticketSharedDraftStartUpdateByGroup($groupId: ID!) {
        ticketSharedDraftStartUpdateByGroup(groupId: $groupId) {
          sharedDraftStarts {
            id
            name
          }
        }
      }
    QUERY
  end

  let(:mock_channel) { build_mock_channel }
  let(:group)        { create(:group) }
  let(:target)       { create(:ticket_shared_draft_start, group:) }
  let(:variables)    { { groupId: gql.id(group) } }

  def subscribe
    gql.execute(subscription, variables:, context: { channel: mock_channel })
  end

  context 'with authenticated user', authenticated_as: :agent do
    let(:agent) do
      create(:agent)
        .tap { |elem| elem.user_groups.create!(group:, access: 'create') }
    end

    it 'subscribes' do
      subscribe

      expect(gql.result.data).to include('sharedDraftStarts' => be_blank)
    end

    it 'receives user updates for target user when draft is touched' do
      subscribe

      target.touch

      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'ticketSharedDraftStartUpdateByGroup', 'sharedDraftStarts'))
        .to contain_exactly(include('id' => gql.id(target)))
    end

    it 'receives user updates for target user when draft is destroyed' do
      target
      subscribe

      target.destroy!

      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'ticketSharedDraftStartUpdateByGroup', 'sharedDraftStarts'))
        .to be_blank
    end

    it 'does not receive user updates for other users' do
      subscribe

      create(:ticket_shared_draft_start)

      expect(mock_channel.mock_broadcasted_messages).to be_empty
    end
  end

  context 'with authenticated customer', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    context 'when subscribing for other users' do
      it 'does not subscribe but returns an authorization error' do
        subscribe

        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated' do
    before { subscribe }
  end
end
