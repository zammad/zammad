# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::AI::TextToolUpdates, type: :graphql do
  let(:mock_channel) { build_mock_channel }
  let(:group1)       { create(:group) }
  let(:ai_text_tool) { create(:ai_text_tool, group_ids: [group1.id]) }

  let(:subscription) do
    <<~QUERY
      subscription aiTextToolUpdates {
        aiTextToolUpdates {
          textToolId
          groupIds
          removeTextToolId
        }
      }
    QUERY
  end

  let(:expected_group_ids) { [gql.id(group1)] }

  let(:expected_msg) do
    {
      'data' => {
        'aiTextToolUpdates' => {
          'textToolId'       => gql.id(ai_text_tool),
          'groupIds'         => expected_group_ids,
          'removeTextToolId' => nil,
        }
      }
    }
  end

  before do
    gql.execute(subscription, context: { channel: mock_channel })

    ai_text_tool
  end

  context 'when authenticated', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'creating a AI text tool triggers subscription' do
      expect(mock_channel.mock_broadcasted_messages.last[:result]).to eq(expected_msg)
    end

    context 'when AI text tool is updated' do
      let(:expected_group_ids) { [] }

      it 'triggers subscription' do
        ai_text_tool.update!(name: 'New Name', group_ids: [])

        expect(mock_channel.mock_broadcasted_messages.last[:result]).to eq(expected_msg)
      end
    end

    context 'when AI text tool is destroyed' do
      let(:expected_msg) do
        {
          'data' => {
            'aiTextToolUpdates' => {
              'textToolId'       => nil,
              'groupIds'         => nil,
              'removeTextToolId' => gql.id(ai_text_tool),
            }
          }
        }
      end

      it 'triggers subscription' do
        ai_text_tool.destroy

        expect(mock_channel.mock_broadcasted_messages.last[:result]).to eq(expected_msg)
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
