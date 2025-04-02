# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Channel::Email::SetNotificationConfiguration, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation channelEmailSetNotificationConfiguration($outboundConfiguration: ChannelEmailOutboundConfigurationInput!) {
        channelEmailSetNotificationConfiguration(outboundConfiguration: $outboundConfiguration) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:smtp_configuration) do
    {
      adapter:   'smtp',
      host:      'smtp.example.com',
      port:      25,
      user:      'some@example.com',
      password:  'password',
      sslVerify: false,
    }
  end

  let(:variables) { { 'outboundConfiguration' => smtp_configuration } }

  before do
    Setting.set('system_online_service', system_online_service) if defined?(system_online_service)

    gql.execute(query, variables: variables)
  end

  context 'when authenticated as admin', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    it 'returns success' do
      expect(gql.result.data).to include({ 'success' => true })
    end

    it 'sets smtp to active and updates configuration' do
      expect(channel_by_adapter('smtp')).to have_attributes(
        active:       true,
        status_out:   'ok',
        last_log_out: nil,
        options:      include(
          outbound: include(
            adapter: 'smtp',
            options: include(
              host:       'smtp.example.com',
              port:       25,
              user:       'some@example.com',
              password:   'password',
              ssl_verify: false,
            )
          )
        )
      )
    end

    context 'when runs in a hosted environment' do
      let(:system_online_service) { true }

      it 'fails with authentication error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'when authenticated as non-admin', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'fails with authentication error' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'

  def channel_by_adapter(adapter)
    Channel
      .where(area: 'Email::Notification')
      .to_a
      .find { _1.options.dig(:outbound, :adapter) == adapter }
  end
end
