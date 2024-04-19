# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::ConfigUpdates, type: :graphql do
  let(:setting) { build(:setting, name: 'broadcast_test', state: setting_value, frontend: true) }

  let(:subscription) do
    <<~QUERY
      subscription configUpdates {
        configUpdates {
          setting {
            key
            value
          }
        }
      }
    QUERY
  end
  let(:mock_channel) { build_mock_channel }
  let(:expected_msg) do
    {
      result: {
        'data' => {
          'configUpdates' => {
            'setting' => {
              'key'   => 'broadcast_test',
              'value' => expected_value
            }
          }
        }
      },
      more:   true,
    }
  end

  context 'when using static value' do
    let(:setting_value)  { 'subscription_test' }
    let(:expected_value) { setting_value }

    it 'broadcasts config update events' do
      gql.execute(subscription, context: { channel: mock_channel })
      setting.save
      expect(mock_channel.mock_broadcasted_messages).to eq([expected_msg])
    end
  end

  context 'when using interpolated value' do
    let(:setting_value)  { 'test #{config.fqdn}' } # rubocop:disable Lint/InterpolationCheck
    let(:expected_value) { "test #{Setting.get('fqdn')}" }

    it 'broadcasts config update events with interpolated string' do
      gql.execute(subscription, context: { channel: mock_channel })
      setting.save
      expect(mock_channel.mock_broadcasted_messages).to eq([expected_msg])
    end
  end
end
