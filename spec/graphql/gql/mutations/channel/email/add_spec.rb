# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Channel::Email::Add, type: :graphql do

  let(:query) do
    <<~QUERY
      mutation channelEmailAdd($input: ChannelEmailAddInput!) {
        channelEmailAdd(input: $input) {
          channel {
            options
            group {
              id
            }
          }
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
  let(:inbound_configuration) do
    {
      adapter:       'imap',
      host:          'nonexisting.host.local',
      port:          993,
      ssl:           'ssl',
      user:          'some@example.com',
      password:      'password',
      folder:        'some_folder',
      keepOnServer:  true,
      sslVerify:     false,
      archive:       true,
      archiveBefore: '2012-03-04T00:00:00',
    }
  end
  let(:group) { create(:group) }

  let(:variables) do
    {
      input: {
        inboundConfiguration:  inbound_configuration,
        outboundConfiguration: outbound_configuration,
        groupId:               gql.id(group),
        emailAddress:          'some.sender@example.com',
        emailRealname:         'John Doe'
      }
    }
  end

  before do
    gql.execute(query, variables: variables)
  end

  context 'when authenticated as admin', authenticated_as: :admin do
    let(:admin) { create(:admin) }
    let(:options_outbound) do
      {
        adapter: 'smtp',
        options: {
          host:       'nonexisting.host.local',
          port:       25,
          user:       'some@example.com',
          password:   'password',
          ssl_verify: false,
        }
      }
    end
    let(:options_inbound) do
      {
        adapter: 'imap',
        options: {
          host:           'nonexisting.host.local',
          port:           993,
          ssl:            'ssl',
          user:           'some@example.com',
          password:       'password',
          folder:         'some_folder',
          keep_on_server: true,
          ssl_verify:     false,
          archive:        true,
          archive_before: '2012-03-04T00:00:00'.to_time, # rubocop:disable Rails/TimeZone
        }
      }
    end

    it 'creates the channel' do
      expect(gql.result.data[:channel]).to include(options: include(
        inbound: options_inbound, outbound: options_outbound
      ))
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
