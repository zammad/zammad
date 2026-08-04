# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
      adapter:        'imap',
      host:           'nonexisting.host.local',
      port:           993,
      ssl:            'ssl',
      user:           'some@example.com',
      password:       'password',
      folder:         'some_folder',
      keepOnServer:   true,
      sslVerify:      false,
      archive:        true,
      archiveBefore:  '2012-03-04T00:00:00',
      archiveStateId: Ticket::State.find_by(name: 'closed').id,
    }
  end

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

  let(:group)      { create(:group) }
  let(:docker_env) { false }

  before do
    if docker_env
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ZAMMAD_DOCKER').and_return('true')
    end

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
          host:             'nonexisting.host.local',
          port:             993,
          ssl:              'ssl',
          user:             'some@example.com',
          password:         'password',
          folder:           'some_folder',
          keep_on_server:   true,
          ssl_verify:       false,
          archive:          true,
          archive_before:   '2012-03-04T00:00:00'.to_time, # rubocop:disable Rails/TimeZone
          archive_state_id: Ticket::State.find_by(name: 'closed').id,
        }
      }
    end

    it 'creates the channel' do
      expect(gql.result.data[:channel]).to include(options: include(
        inbound: options_inbound, outbound: options_outbound
      ))
    end

    context 'when outbound adapter is sendmail' do
      let(:outbound_configuration) { { adapter: 'sendmail' } }

      it 'creates the channel' do
        expect(gql.result.data[:channel]).to include(options: include(
          outbound: include(adapter: 'sendmail')
        ))
      end

      context 'when running in docker environment' do
        let(:docker_env) { true }

        it 'fails with validation error' do
          expect(gql.result.error_message).to include('Unsupported outbound adapter: "sendmail"')
        end
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
