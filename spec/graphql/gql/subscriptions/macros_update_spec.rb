# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::MacrosUpdate, type: :graphql do
  let(:mock_channel) { build_mock_channel }
  let(:group1)       { create(:group) }
  let(:macro)        { create(:macro, group_ids: [group1.id]) }

  let(:subscription) do
    <<~QUERY
      subscription macrosUpdate {
        macrosUpdate {
          macroId
          groupIds
          removeMacroId
        }
      }
    QUERY
  end

  let(:expected_group_ids) { [gql.id(group1)] }

  let(:expected_msg) do
    {
      'data' => {
        'macrosUpdate' => {
          'macroId'       => gql.id(macro),
          'groupIds'      => expected_group_ids,
          'removeMacroId' => nil
        }
      }
    }
  end

  before do
    gql.execute(subscription, context: { channel: mock_channel })

    macro
  end

  context 'when authenticated', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'creating a macro triggers subscription' do
      expect(mock_channel.mock_broadcasted_messages.last[:result]).to eq(expected_msg)
    end

    context 'when macro is updated' do
      let(:expected_group_ids) { [] }

      it 'triggers subscription' do
        macro.update!(name: 'New Name', group_ids: [])

        expect(mock_channel.mock_broadcasted_messages.last[:result]).to eq(expected_msg)
      end
    end

    context 'when macro is destroyed' do
      let(:expected_msg) do
        {
          'data' => {
            'macrosUpdate' => {
              'macroId'       => nil,
              'groupIds'      => nil,
              'removeMacroId' => gql.id(macro),
            }
          }
        }
      end

      it 'triggers subscription' do
        macro.destroy

        expect(mock_channel.mock_broadcasted_messages.last[:result]).to eq(expected_msg)
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
