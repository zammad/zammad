# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe EmailHelper::Verify, integration: true do
  describe '#email' do
    subject(:verify_result) { described_class.email(verify_params) }

    context 'when doing real tests' do
      let(:mailbox_user)     { real_user_data.first }
      let(:mailbox_password) { real_user_data.last }

      shared_examples 'do real testing' do
        it { is_expected.to include(result: 'ok') }
      end

      context 'with zammad', required_envs: %w[EMAILHELPER_MAILBOX_1] do
        let(:real_user_data) { ENV['EMAILHELPER_MAILBOX_1'].split(':') }

        let(:verify_params) do
          {
            inbound:  {
              adapter: 'imap',
              options: {
                host:     'mx2.zammad.com',
                port:     993,
                ssl:      true,
                user:     mailbox_user,
                password: mailbox_password,
              },
            },
            outbound: {
              adapter: 'smtp',
              options: {
                host:     'mx2.zammad.com',
                port:     587,
                user:     mailbox_user,
                password: mailbox_password,
              },
            },
            sender:   mailbox_user,
          }
        end

        include_examples 'do real testing'
      end

      context 'with gmail', required_envs: %w[EMAILHELPER_MAILBOX_2] do
        let(:real_user_data) { ENV['EMAILHELPER_MAILBOX_2'].split(':') }

        let(:verify_params) do
          {
            inbound:  {
              adapter: 'pop3',
              options: {
                host:     'pop.gmail.com',
                port:     995,
                ssl:      true,
                user:     mailbox_user,
                password: mailbox_password,
              },
            },
            outbound: {
              adapter: 'smtp',
              options: {
                host:      'smtp.gmail.com',
                port:      587,
                start_tls: true,
                user:      mailbox_user,
                password:  mailbox_password,
              },
            },
            sender:   mailbox_user,
          }
        end

        include_examples 'do real testing'
      end
    end
  end
end
