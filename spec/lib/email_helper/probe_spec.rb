# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe EmailHelper::Probe, integration: true do
  let(:expected_result_failed) do
    {
      result:  'failed',
      message: message_human,
    }
  end

  let(:expected_result_invalid) do
    {
      result:        'invalid',
      message_human: message_human,
    }
  end

  shared_examples 'probe tests with invalid result' do
    it 'contains all information for an invalid result' do # rubocop:disable RSpec/ExampleLength
      expect(probe_result).to include(
        result:        expected_result_invalid[:result],
        message_human: be_in(expected_result_invalid[:message_human]),
        settings:      include(
          options: include(
            host: host,
          ),
        ),
      )
    end
  end

  describe '#inbound' do
    subject(:probe_result) { described_class.inbound(inbound_params) }

    let(:inbound_params) do
      {
        adapter: adapter,
        options: {
          host:     host,
          port:     port,
          ssl:      true,
          user:     user,
          password: password,
        },
      }
    end

    let(:adapter)  { 'imap' }
    let(:port)     { 993 }
    let(:user)     { 'some@example.com' }
    let(:password) { 'password' }

    context 'with unknown adapter' do
      let(:adapter)       { 'imap2' }
      let(:host)          { 'nonexisting_host' }
      let(:message_human) { "Unknown adapter '#{adapter}'" }

      it { is_expected.to eq(expected_result_failed) }
    end

    context 'when network issues are present' do
      let(:host)          { 'nonexisting_host' }
      let(:message_human) { 'The hostname could not be found.' }

      include_examples 'probe tests with invalid result'
    end

    context 'when an imap service with a blocked port is used' do
      let(:host)          { '127.0.0.1' }
      let(:port)          { 8 } # no service to be expected
      let(:message_human) { 'The connection was refused.' }

      include_examples 'probe tests with invalid result'
    end

    context 'when host is not reachable' do
      let(:host)          { '192.168.254.254' }
      let(:message_human) { [ 'This host cannot be reached.', 'There is no route to this host.' ] }

      before do
        stub_const('Channel::Driver::Imap::CHECK_ONLY_TIMEOUT', 1.second)
      end

      include_examples 'probe tests with invalid result'
    end

    context 'when incorrect credentials are used' do
      let(:host)          { 'imap.gmail.com' }
      let(:message_human) { [ 'Authentication failed due to incorrect username.', 'Authentication failed due to incorrect credentials.' ] }

      include_examples 'probe tests with invalid result'
    end

    context 'when authentication fails' do
      let(:host)          { 'mx2.zammad.com' }
      let(:message_human) { [ 'Authentication failed.', 'This host cannot be reached.' ] }

      before do
        stub_const('Channel::Driver::Imap::CHECK_ONLY_TIMEOUT', 1.second)
      end

      include_examples 'probe tests with invalid result'
    end

    context 'when doing a real test', required_envs: %w[EMAILHELPER_MAILBOX_1] do
      let(:host)           { 'mx2.zammad.com' }
      let(:real_user_data) { ENV['EMAILHELPER_MAILBOX_1'].split(':') }
      let(:user)           { real_user_data.first }
      let(:password)       { real_user_data.last }

      it { is_expected.to include(result: 'ok') }
    end
  end

  describe '#outbound' do
    subject(:probe_result) { described_class.outbound(outbound_params, user) }

    let(:outbound_params) do
      {
        adapter: adapter,
        options: {
          host:      host,
          port:      port,
          start_tls: true,
          user:      user,
          password:  password,
        },
      }
    end

    let(:adapter)  { 'smtp' }
    let(:port)     { 25 }
    let(:user)     { 'some@example.com' }
    let(:password) { 'password' }

    context 'with unknown adapter' do
      let(:adapter)       { 'imap2' }
      let(:host)          { 'nonexisting_host' }
      let(:message_human) { "Unknown adapter '#{adapter}'" }

      it { is_expected.to eq(expected_result_failed) }
    end

    context 'when network issues are present' do
      let(:host)          { 'nonexisting_host' }
      let(:message_human) { 'The hostname could not be found.' }

      include_examples 'probe tests with invalid result'
    end

    context 'when an imap service with a blocked port is used' do
      let(:host)          { '127.0.0.1' }
      let(:port)          { 8 } # no service to be expected
      let(:message_human) { 'The connection was refused.' }

      include_examples 'probe tests with invalid result'
    end

    context 'when host is not reachable' do
      let(:host)          { '192.168.254.254' }
      let(:message_human) { [ 'This host cannot be reached.', 'There is no route to this host.' ] }

      before do
        stub_const('Channel::Driver::Smtp::DEFAULT_OPEN_TIMEOUT', 2.seconds)
        stub_const('Channel::Driver::Smtp::DEFAULT_READ_TIMEOUT', 4.seconds)
      end

      include_examples 'probe tests with invalid result'
    end

    context 'when incorrect credentials are used' do
      let(:host)          { 'smtp.gmail.com' }
      let(:message_human) { 'Authentication failed.' }

      include_examples 'probe tests with invalid result'
    end

    context 'when authentication fails' do
      let(:host)          { 'mx2.zammad.com' }
      let(:port)          { 587 }
      let(:message_human) { 'Authentication failed.' }

      before do
        stub_const('Channel::Driver::Smtp::DEFAULT_OPEN_TIMEOUT', 5.seconds)
        stub_const('Channel::Driver::Smtp::DEFAULT_READ_TIMEOUT', 10.seconds)
      end

      include_examples 'probe tests with invalid result'
    end

    context 'when doing a real test', required_envs: %w[EMAILHELPER_MAILBOX_1] do
      let(:host)           { 'mx2.zammad.com' }
      let(:port)           { 587 }
      let(:real_user_data) { ENV['EMAILHELPER_MAILBOX_1'].split(':') }
      let(:user)           { real_user_data.first }
      let(:password)       { real_user_data.last }

      let(:outbound_params) do
        {
          adapter: adapter,
          options: {
            host:     host,
            port:     port,
            user:     user,
            password: password,
          },
        }
      end

      before do
        stub_const('Channel::Driver::Smtp::DEFAULT_OPEN_TIMEOUT', 5.seconds)
        stub_const('Channel::Driver::Smtp::DEFAULT_READ_TIMEOUT', 10.seconds)
      end

      it { is_expected.to include(result: 'ok') }
    end
  end

  describe '#full' do
    subject(:probe_result) { described_class.full(full_params) }

    let(:full_params) do
      {
        email:    email,
        password: password,
      }
    end

    context 'when providing invalid information' do
      let(:email)    { 'invalid_format' }
      let(:password) { 'somepass' }

      it 'contains all information for an invalid probe' do
        expect(probe_result)
          .to include(
            result: 'invalid'
          )
          .and not_include('setting')
      end
    end

    context 'when doing real tests' do
      let(:email)    { real_user_data.first }
      let(:password) { real_user_data.last }

      shared_examples 'do real testing' do
        it 'contains all information for a successful probe' do # rubocop:disable RSpec/ExampleLength
          expect(probe_result).to include(result: 'ok')
            .and include(
              setting: include(
                inbound: include(
                  options: include(
                    host: inbound_host
                  ),
                ),
              ),
            )
            .and include(
              setting: include(
                outbound: include(
                  options: include(
                    host: outbound_host,
                  ),
                ),
              ),
            )
        end
      end

      context 'with zammad', required_envs: %w[EMAILHELPER_MAILBOX_1] do
        let(:real_user_data) { ENV['EMAILHELPER_MAILBOX_1'].split(':') }
        let(:inbound_host)   { 'mx2.zammad.com' }
        let(:outbound_host)  { inbound_host }

        before do
          stub_const('Channel::Driver::Smtp::DEFAULT_OPEN_TIMEOUT', 5.seconds)
          stub_const('Channel::Driver::Smtp::DEFAULT_READ_TIMEOUT', 10.seconds)

          options = {
            host:      inbound_host,
            port:      993,
            ssl:       true,
            auth_type: 'LOGIN',
            user:      email,
            password:  password,
          }
          imap_delete_old_mails(options)
        end

        include_examples 'do real testing'
      end

      context 'with gmail', required_envs: %w[EMAILHELPER_MAILBOX_2] do
        let(:real_user_data) { ENV['EMAILHELPER_MAILBOX_2'].split(':') }
        let(:inbound_host)   { 'pop.gmail.com' }
        let(:outbound_host)  { 'smtp.gmail.com' }

        include_examples 'do real testing'
      end
    end
  end
end
