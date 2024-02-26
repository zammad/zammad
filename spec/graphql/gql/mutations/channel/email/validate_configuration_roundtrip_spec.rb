# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Channel::Email::ValidateConfigurationRoundtrip, type: :graphql do

  let(:query) do
    <<~QUERY
      mutation channelEmailValidateConfigurationRoundtrip($inboundConfiguration: ChannelEmailInboundConfigurationInput!, $outboundConfiguration: ChannelEmailOutboundConfigurationInput!, $emailAddress: String!) {
        channelEmailValidateConfigurationRoundtrip(inboundConfiguration: $inboundConfiguration, outboundConfiguration: $outboundConfiguration, emailAddress: $emailAddress) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:failing_outbound_configuration) do
    {
      adapter:   'smtp',
      host:      'nonexisting.host.local',
      port:      25,
      user:      'some@example.com',
      password:  'password',
      sslVerify: false,
    }
  end
  let(:failing_inbound_configuration) do
    {
      'adapter'   => 'imap',
      'host'      => 'nonexisting.host.local',
      'port'      => 993,
      'ssl'       => 'ssl',
      'user'      => 'some@example.com',
      'password'  => 'password',
      'folder'    => 'some_folder',
      'sslVerify' => false,
    }
  end

  let(:variables)           { { 'inboundConfiguration' => failing_inbound_configuration, 'outboundConfiguration' => failing_outbound_configuration, emailAddress: 'some.sender@example.com' } }
  let(:probe_full_response) { nil }

  before do
    allow(EmailHelper::Verify).to receive(:email).and_return(probe_full_response) if probe_full_response
    allow_any_instance_of(Channel::Driver::Smtp).to receive(:deliver).and_raise(Errno::EHOSTUNREACH)
    gql.execute(query, variables: variables)
  end

  context 'when authenticated as admin', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    context 'with successful probe' do
      let(:probe_full_response) { { result: 'ok' } }

      it 'finds configuration data' do
        expect(gql.result.data).to eq({ 'success' => true, 'errors' => nil })
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
