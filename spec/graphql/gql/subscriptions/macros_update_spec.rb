# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::MacrosUpdate, type: :graphql do
  let(:mock_channel) { build_mock_channel }

  let(:subscription) do
    <<~QUERY
      subscription macrosUpdate {
        macrosUpdate {
          macroUpdated
        }
      }
    QUERY
  end

  let(:expected_msg) do
    {
      result: {
        'data' => {
          'macrosUpdate' => {
            'macroUpdated' => true
          }
        }
      },
      more:   true
    }
  end

  before do
    gql.execute(subscription, context: { channel: mock_channel })
  end

  context 'when authenticated', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'creating a macro triggers subscription' do
      create(:macro)
      expect(mock_channel.mock_broadcasted_messages).to eq([expected_msg])
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
