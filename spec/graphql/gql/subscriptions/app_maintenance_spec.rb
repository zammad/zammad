# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::AppMaintenance, type: :graphql do

  let(:subscription) do
    <<~QUERY
      subscription appMaintenance {
        appMaintenance {
          type
        }
      }
    QUERY
  end
  let(:mock_channel)  { build_mock_channel }
  let(:expected_type) { 'app_version' }
  let(:expected_msg) do
    {
      result: {
        'data' => {
          'appMaintenance' => {
            'type' => expected_type
          }
        }
      },
      more:   true,
    }
  end

  shared_examples 'app maintenance subscription' do
    it 'correct app maintenance update/change event' do
      expect(mock_channel.mock_broadcasted_messages).to eq([expected_msg])
    end
  end

  context 'when app maintenance update/change events (trigger actions in the frontend) are triggered' do
    before do
      gql.execute(subscription, context: { channel: mock_channel })
      AppVersion.set(true, app_version_set)
    end

    context 'when app version event is triggered' do
      let(:app_version_set) { AppVersion::MSG_APP_VERSION }

      include_examples 'app maintenance subscription'
    end

    context 'when restart auto event is triggered' do
      let(:app_version_set) { AppVersion::MSG_RESTART_AUTO }
      let(:expected_type)   { 'restart_auto' }

      include_examples 'app maintenance subscription'
    end

    context 'when restart manual event is triggered' do
      let(:app_version_set) { AppVersion::MSG_RESTART_MANUAL }
      let(:expected_type)   { 'restart_manual' }

      include_examples 'app maintenance subscription'
    end

    context 'when config change event is triggered' do
      let(:app_version_set) { AppVersion::MSG_CONFIG_CHANGED }
      let(:expected_type)   { 'config_changed' }

      include_examples 'app maintenance subscription'
    end
  end
end
