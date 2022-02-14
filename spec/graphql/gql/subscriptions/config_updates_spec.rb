# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::ConfigUpdates, type: :graphql do

  let(:subscription) { read_graphql_file('common/graphql/subscriptions/configUpdates.graphql') }
  let(:mock_channel) { build_mock_channel }
  let(:expected_msg) do
    {
      result: {
        'data' => {
          'configUpdates' => {
            'setting' => {
              'key'   => 'product_name',
              'value' => 'subscription_test'
            }
          }
        }
      },
      more:   true,
    }
  end

  it 'broadcasts config update events' do
    graphql_execute(subscription, context: { channel: mock_channel })
    Setting.set('product_name', 'subscription_test')
    expect(mock_channel.mock_broadcasted_messages).to eq([expected_msg])
  end
end
