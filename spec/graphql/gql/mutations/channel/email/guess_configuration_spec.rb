# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Channel::Email::GuessConfiguration, type: :graphql do

  let(:query) do
    <<~QUERY
      mutation channelEmailGuessConfiguration($emailAddress: String!, $password: String!) {
        channelEmailGuessConfiguration(emailAddress: $emailAddress, password: $password) {
          result {
            inboundConfiguration {
              adapter
              host
              port
              ssl
              user
              password
              sslVerify
              folder
            }
            outboundConfiguration {
              adapter
              host
              port
              user
              password
              sslVerify
            }
            mailboxStats {
              contentMessages
              archivePossible
              archiveWeekRange
            }
          }
        }
      }
    QUERY
  end

  let(:variables)           { { emailAddress: 'admin@example.com', password: '1234' } }
  let(:probe_full_response) { { result: 'failed' } }

  before do
    allow(EmailHelper::Probe).to receive(:full).and_return(probe_full_response)
    gql.execute(query, variables: variables)
  end

  context 'when authenticated as admin', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    context 'with successful probe' do

      let(:probe_full_response) do
        # Example from function documentation
        {
          result:             'ok',
          content_messages:   23,
          archive_possible:   true,
          archive_week_range: 2,
          setting:            {
            inbound:  {
              adapter: 'imap',
              options: {
                host:       'imap.gmail.com',
                port:       993,
                ssl:        probe_ssl,
                start_tls:  probe_starttls,
                user:       'some@example.com',
                password:   'password',
                folder:     'some_folder',
                ssl_verify: false,
              },
            },
            outbound: {
              adapter: 'smtp',
              options: {
                host:       'smtp.gmail.com',
                port:       25,
                user:       'some@example.com',
                password:   'password',
                ssl_verify: false,
              },
            },
          },
        }
      end

      let(:expected_result) do
        {
          'result' => {
            'mailboxStats'          => {
              'contentMessages'  => 23,
              'archivePossible'  => true,
              'archiveWeekRange' => 2,
            },
            'inboundConfiguration'  => {
              'adapter'   => 'imap',
              'host'      => 'imap.gmail.com',
              'port'      => 993,
              'ssl'       => expected_ssl,
              'user'      => 'some@example.com',
              'password'  => 'password',
              'folder'    => 'some_folder',
              'sslVerify' => false,
            },
            'outboundConfiguration' => {
              'adapter'   => 'smtp',
              'host'      => 'smtp.gmail.com',
              'port'      => 25,
              'user'      => 'some@example.com',
              'password'  => 'password',
              'sslVerify' => false,
            }
          }
        }
      end

      context 'when both SSL and STARTTLS are off' do
        let(:probe_ssl)      { false }
        let(:probe_starttls) { false }
        let(:expected_ssl)   { 'off' }

        it 'finds configuration data' do
          expect(gql.result.data).to eq(expected_result)
        end
      end

      context 'when both STARTTLS is on' do
        let(:probe_ssl)      { false }
        let(:probe_starttls) { true }
        let(:expected_ssl)   { 'starttls' }

        it 'finds configuration data' do
          expect(gql.result.data).to eq(expected_result)
        end
      end

      context 'when both SSL is on' do
        let(:probe_ssl)      { true }
        let(:probe_starttls) { false }
        let(:expected_ssl)   { 'ssl' }

        it 'finds configuration data' do
          expect(gql.result.data).to eq(expected_result)
        end
      end

      context 'when both SSL and STARTTLS are on' do
        let(:probe_ssl)      { true }
        let(:probe_starttls) { true }
        let(:expected_ssl)   { 'starttls' }

        it 'finds configuration data' do
          expect(gql.result.data).to eq(expected_result)
        end
      end
    end

    context 'with failed probe' do

      let(:probe_full_response) do
        {
          result: 'failed',
        }
      end

      let(:expected_result) do
        {
          'result' => {
            'mailboxStats'          => nil,
            'inboundConfiguration'  => nil,
            'outboundConfiguration' => nil,
          }
        }
      end

      it 'finds configuration data' do
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
