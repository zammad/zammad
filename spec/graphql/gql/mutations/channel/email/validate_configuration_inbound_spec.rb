# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Channel::Email::ValidateConfigurationInbound, type: :graphql do

  let(:query) do
    <<~QUERY
      mutation channelEmailValidateConfigurationInbound($inboundConfiguration: ChannelEmailInboundConfigurationInput!) {
        channelEmailValidateConfigurationInbound(inboundConfiguration: $inboundConfiguration) {
          success
          mailboxStats {
            contentMessages
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:failing_configuration) do
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

  let(:variables)           { { 'inboundConfiguration' => failing_configuration } }
  let(:probe_full_response) { nil }
  let(:error)               { nil }

  before do
    allow(EmailHelper::Probe).to receive(:inbound).and_return(probe_full_response) if probe_full_response
    allow_any_instance_of(Channel::Driver::Imap).to receive(:check_configuration).and_raise(error) if error
    gql.execute(query, variables: variables)
  end

  context 'when authenticated as admin', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    context 'with successful probe' do
      let(:probe_full_response) { { result: 'ok', content_messages: 23 } }

      let(:expected_result) do
        {
          'success'      => true,
          'mailboxStats' => {
            'contentMessages' => 23,
          },
          'errors'       => nil,
        }
      end

      it 'finds configuration data' do
        expect(gql.result.data).to eq(expected_result)
      end
    end

    context 'with failed probe' do
      let(:error) { SocketError.new('getaddrinfo: nodename nor servname provided, or not known') }
      let(:expected_result) do
        {
          'success'      => false,
          'mailboxStats' => nil,
          'errors'       => [{ 'field' => 'inbound.host', 'message' => 'The hostname could not be found.' }],
        }
      end

      it 'returns error messages' do
        expect(gql.result.data).to eq(expected_result)
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
