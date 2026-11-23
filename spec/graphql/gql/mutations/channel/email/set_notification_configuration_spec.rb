# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What the check and the save do is covered by spec/services/service/system/check_and_set_email_notification_configuration_spec.rb —
#   this covers the GraphQL surface only: authorization, argument mapping, and the payload.
RSpec.describe Gql::Mutations::Channel::Email::SetNotificationConfiguration, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation channelEmailSetNotificationConfiguration($outboundConfiguration: ChannelEmailOutboundConfigurationInput!, $testAddress: String) {
        channelEmailSetNotificationConfiguration(outboundConfiguration: $outboundConfiguration, testAddress: $testAddress) {
          success
          refused
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

  let(:variables)      { { 'outboundConfiguration' => smtp_configuration } }
  let(:service_result) { { result: 'ok' } }

  before do
    Setting.set('system_online_service', system_online_service) if defined?(system_online_service)

    allow(Service::System::CheckAndSetEmailNotificationConfiguration).to receive(:execute).and_return(service_result)

    gql.execute(query, variables: variables)
  end

  context 'when authenticated as admin', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    it 'returns success' do
      expect(gql.result.data).to include({ 'success' => true, 'refused' => false, 'errors' => nil })
    end

    it 'passes the configuration to the service' do
      expect(Service::System::CheckAndSetEmailNotificationConfiguration).to have_received(:execute).with(
        adapter:           'smtp',
        new_configuration: include(host: 'smtp.example.com', ssl_verify: false),
        test_address:      nil,
      )
    end

    context 'with a test address' do
      let(:variables) { super().merge('testAddress' => 'admin@example.com') }

      it 'passes the test address to the service' do
        expect(Service::System::CheckAndSetEmailNotificationConfiguration).to have_received(:execute).with(
          include(test_address: 'admin@example.com'),
        )
      end
    end

    context 'when the server refused the test email of the usual check' do
      let(:service_result) do
        {
          result:        'invalid',
          message:       'smtp.example.com: 554 5.7.1 Relay access denied',
          message_human: nil,
          invalid_field: {},
          refused:       true,
        }
      end

      it 'returns the failed check with the refusal mark' do
        expect(gql.result.data).to include(
          'success' => false,
          'refused' => true,
          'errors'  => [
            { 'message' => 'smtp.example.com: 554 5.7.1 Relay access denied', 'field' => nil },
          ],
        )
      end

      context 'when the reply names a field' do
        let(:service_result) { super().merge(message_human: 'The connection was refused.', invalid_field: { host: true }) }

        it 'keeps the field of the error' do
          expect(gql.result.data).to include(
            'success' => false,
            'refused' => true,
            'errors'  => [
              { 'message' => 'The connection was refused.', 'field' => 'outbound.host' },
            ],
          )
        end
      end
    end

    context 'when the check failed' do
      let(:service_result) do
        {
          result:        'invalid',
          message:       'Authentication on smtp.example.com failed: 535 5.7.8 authentication failed',
          message_human: 'Authentication failed.',
          invalid_field: { user: true, password: true },
        }
      end

      it 'returns user errors for the fields without the refusal mark' do
        expect(gql.result.data).to include(
          'success' => false,
          'refused' => false,
          'errors'  => [
            { 'message' => 'Authentication failed.', 'field' => 'outbound.user' },
            { 'message' => 'Authentication failed.', 'field' => 'outbound.password' },
          ],
        )
      end
    end

    context 'when the server refused the test email to the test address' do
      let(:variables) { super().merge('testAddress' => 'admin@example.com') }
      let(:service_result) do
        {
          result:        'invalid',
          message:       'smtp.example.com: 554 5.7.1 Relay access denied',
          message_human: nil,
          invalid_field: {},
        }
      end

      it 'returns a user error without the refusal mark' do
        expect(gql.result.data).to include(
          'success' => false,
          'refused' => false,
          'errors'  => [
            { 'message' => 'smtp.example.com: 554 5.7.1 Relay access denied', 'field' => nil },
          ],
        )
      end
    end

    context 'when the test address is no email address' do
      let(:variables) { super().merge('testAddress' => 'admin') }
      let(:service_result) do
        {
          result:        'invalid',
          message:       'Please enter a valid email address.',
          message_human: 'Please enter a valid email address.',
          invalid_field: { test_address: true },
        }
      end

      it 'returns a user error for the test address' do
        expect(gql.result.data).to include(
          'success' => false,
          'errors'  => [
            { 'message' => 'Please enter a valid email address.', 'field' => 'outbound.testAddress' },
          ],
        )
      end
    end

    context 'when runs in a hosted environment' do
      let(:system_online_service) { true }

      it 'fails with authentication error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end

      it 'does not call the service' do
        expect(Service::System::CheckAndSetEmailNotificationConfiguration).not_to have_received(:execute)
      end
    end
  end

  context 'when authenticated as non-admin', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'fails with authentication error' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end

    it 'does not call the service' do
      expect(Service::System::CheckAndSetEmailNotificationConfiguration).not_to have_received(:execute)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
