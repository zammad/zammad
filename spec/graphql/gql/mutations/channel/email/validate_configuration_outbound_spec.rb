# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Channel::Email::ValidateConfigurationOutbound, type: :graphql do

  let(:query) do
    <<~QUERY
      mutation channelEmailValidateConfigurationOutbound($outboundConfiguration: ChannelEmailOutboundConfigurationInput!, $emailAddress: String!) {
        channelEmailValidateConfigurationOutbound(outboundConfiguration: $outboundConfiguration, emailAddress: $emailAddress) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:outbound_configuration) do
    {
      adapter:   'smtp',
      host:      'nonexisting.host.local',
      port:      25,
      user:      'some@example.com',
      password:  'password',
      sslVerify: false,
    }
  end

  let(:variables)           { { 'outboundConfiguration' => outbound_configuration, emailAddress: 'some.sender@example.com' } }
  let(:probe_full_response) { nil }
  let(:docker_env)          { false }

  before do
    if docker_env
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ZAMMAD_DOCKER').and_return('true')
    end

    allow(EmailHelper::Probe).to receive(:outbound).and_return(probe_full_response) if probe_full_response
    allow_any_instance_of(Channel::Driver::Smtp).to receive(:deliver).and_raise(Errno::EHOSTUNREACH)
    gql.execute(query, variables: variables)
  end

  context 'when authenticated as admin', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    context 'with successful probe' do
      let(:probe_full_response) { { result: 'ok' } }

      it 'validates configuration data' do
        expect(gql.result.data).to eq({ 'success' => true, 'errors' => nil })
      end

      context 'when outbound adapter is sendmail' do
        let(:outbound_configuration) { { adapter: 'sendmail' } }

        it 'validates configuration data' do
          expect(gql.result.data).to eq({ 'success' => true, 'errors' => nil })
        end

        context 'when running in docker environment' do
          let(:docker_env) { true }

          it 'fails with validation error' do
            expect(gql.result.error_message).to include('Unsupported outbound adapter: "sendmail"')
          end
        end
      end
    end

    context 'with failed probe' do
      it 'returns error messages' do
        expect(gql.result.data).to eq({ 'success' => false, 'errors' => [{ 'field' => 'outbound.host', 'message' => 'There is no route to this host.' }] })
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
end
