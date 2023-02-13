# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe EmailHelper::Probe, integration: true, required_envs: %w[MAIL_SERVER MAIL_ADDRESS MAIL_PASS] do
  let(:expected_result_failed)  { { result: 'failed', message: message_human, } }
  let(:expected_result_invalid) { { result: 'invalid', message_human: message_human, } }

  before do
    allow(EmailHelper).to receive(:mx_records).and_return([ ENV['MAIL_SERVER'] ])
  end

  shared_examples 'probe tests with invalid result' do
    it 'contains all information for an invalid result' do
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
      let(:host)          { nil }
      let(:message_human) { [ 'This host cannot be reached.', 'There is no route to this host.' ] }

      before do
        allow(Socket).to receive(:tcp).and_raise(Errno::EHOSTUNREACH)
      end

      include_examples 'probe tests with invalid result'
    end

    context 'when authentication fails' do
      let(:host)          { ENV['MAIL_SERVER'] }
      let(:message_human) { [ 'Authentication failed.', 'This host cannot be reached.' ] }

      include_examples 'probe tests with invalid result'
    end

    context 'when doing a real test' do
      let(:host)           { ENV['MAIL_SERVER'] }
      let(:user)           { ENV['MAIL_ADDRESS'] }
      let(:password)       { ENV['MAIL_PASS'] }

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
      let(:host)          { nil }
      let(:message_human) { [ 'This host cannot be reached.', 'There is no route to this host.' ] }

      before do
        allow(Socket).to receive(:tcp).and_raise(Errno::EHOSTUNREACH)
      end

      include_examples 'probe tests with invalid result'
    end

    context 'when authentication fails' do
      let(:host)          { ENV['MAIL_SERVER'] }
      let(:port)          { 25 }
      let(:message_human) { 'Authentication failed.' }

      include_examples 'probe tests with invalid result'
    end

    context 'when doing a real test' do
      let(:host)           { ENV['MAIL_SERVER'] }
      let(:port)           { 25 }
      let(:user)           { ENV['MAIL_ADDRESS'] }
      let(:password)       { ENV['MAIL_PASS'] }

      let(:outbound_params) do
        {
          adapter: adapter,
          options: {
            host:     host,
            port:     port,
            user:     user,
            ssl:      false,
            password: password,
          },
        }
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
      let(:email)          { ENV['MAIL_ADDRESS'] }
      let(:password)       { ENV['MAIL_PASS'] }

      shared_examples 'do real testing' do
        it 'contains all information for a successful probe' do
          expect(probe_result).to include(result: 'ok')
            .and include(
              setting: include(
                inbound: include(
                  options: include(
                    host: host
                  ),
                ),
              ),
            )
            .and include(
              setting: include(
                outbound: include(
                  options: include(
                    host: host,
                  ),
                ),
              ),
            )
        end
      end

      context 'when doing a real test' do
        let(:host) { ENV['MAIL_SERVER'] }

        include_examples 'do real testing'
      end
    end
  end
end
