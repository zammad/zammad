# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe EmailHelper::Probe do
  describe '.full' do
    let(:password) { 'probe-mailbox-password' }
    let(:server) do
      {
        adapter: 'imap',
        options: {
          host:     'mail.example.com',
          port:     993,
          ssl:      true,
          user:     'user@example.com',
          password: password,
        },
      }
    end
    let(:debug_log) { [] }

    before do
      allow(Rails.logger).to receive(:debug) { |*args, &block| debug_log << (block ? block.call : args.first).to_s }
      allow(EmailHelper).to receive(:mx_records).and_return([])
      allow(described_class).to receive_messages(
        inbound:  { result: 'ok', settings: server },
        outbound: { result: 'ok', settings: server },
      )
    end

    shared_examples 'not logging the mailbox password' do |log_line|
      it 'does not log the mailbox password', :aggregate_failures do
        described_class.full(email: 'user@example.com', password: password)

        expect(debug_log).to include(a_string_including(log_line))
        expect(debug_log).to all(not_include(password))
      end
    end

    context 'when using a provider' do
      before do
        allow(EmailHelper).to receive(:provider).and_return(
          example: { domain: 'example.com', inbound: server.deep_dup, outbound: server.deep_dup },
        )
      end

      include_examples 'not logging the mailbox password', 'INBOUND PROBE PROVIDER'
    end

    context 'when guessing the server' do
      before do
        allow(EmailHelper).to receive_messages(
          provider:                {},
          provider_inbound_mx:     [],
          provider_outbound_mx:    [],
          provider_inbound_guess:  [server.deep_dup],
          provider_outbound_guess: [server.deep_dup],
        )
      end

      include_examples 'not logging the mailbox password', 'PROBE FULL SUCCESS'
    end
  end
end
