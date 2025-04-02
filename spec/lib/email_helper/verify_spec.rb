# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe EmailHelper::Verify, integration: true, required_envs: %w[MAIL_SERVER MAIL_ADDRESS MAIL_PASS] do
  describe '#email' do
    subject(:verify_result) { described_class.email(verify_params) }

    let(:mailbox_user)     { ENV['MAIL_ADDRESS'] }
    let(:mailbox_password) { ENV['MAIL_PASS'] }
    let(:verify_params) do
      {
        inbound:  {
          adapter: 'imap',
          options: {
            host:       ENV['MAIL_SERVER'],
            port:       993,
            ssl:        'true',
            user:       mailbox_user,
            password:   mailbox_password,
            ssl_verify: false,
          },
        },
        outbound: {
          adapter: 'smtp',
          options: {
            host:       ENV['MAIL_SERVER'],
            port:       25,
            ssl:        false,
            user:       mailbox_user,
            password:   mailbox_password,
            ssl_verify: false,
          },
        },
        sender:   mailbox_user,
      }
    end

    it { is_expected.to include(result: 'ok') }
  end
end
