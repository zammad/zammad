# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe EmailHelper do

  # This should continue to be a live test using DNS.
  describe '#mx_records', integration: true do
    context 'when checking for regular domains' do
      subject(:result) { described_class.mx_records(domain) }

      let(:domain) { 'zammad.com' }

      it { is_expected.to eq(['mx2.zammad.com']) }
    end
  end

  describe '#parse_email' do
    subject(:result) { described_class.parse_email(mail_address) }

    context 'when parsing a well formatted mail address' do
      let(:mail_address) { 'somebody@example.com' }
      let(:result)       { [ 'somebody', 'example.com' ] }

      it { is_expected.to eq(result) }
    end

    context 'when parsing another well formatted mail address' do
      let(:mail_address) { 'somebody+test@example.com' }
      let(:result)       { [ 'somebody+test', 'example.com' ] }

      it { is_expected.to eq(result) }
    end

    context 'when parsing an invalid mail address' do
      let(:mail_address) { 'somebody+testexample.com' }
      let(:result)       { [ nil, nil ] }

      it { is_expected.to eq(result) }
    end
  end

  describe '#provider' do
    subject(:result) { described_class.provider(mail_address, password) }

    context 'when checking for gmail' do
      let(:mail_address) { 'linus@kernel.org' }
      let(:password)     { 'some_pw' }

      context 'when inbound' do
        let(:ssl_options)             { { key: 'ssl', value: 'ssl' } }
        let(:expected_result_inbound) { provider_setting('imap', 993, mail_address, password, ssl_options) }

        it 'contains correct inbound provider information' do
          expect(described_class.provider(mail_address, password)[:google_imap][:inbound]).to eq(expected_result_inbound)
        end
      end

      context 'when outbound' do
        let(:ssl_options)              { { key: 'start_tls', value: true } }
        let(:expected_result_outbound) { provider_setting('smtp', 587, mail_address, password, ssl_options) }

        it 'contains correct outbound provider information' do
          expect(described_class.provider(mail_address, password)[:google_imap][:outbound]).to eq(expected_result_outbound)
        end
      end

      def provider_setting(adapter, port, user, password, ssl_options)
        {
          adapter: adapter,
          options: {
            host:     "#{adapter}.gmail.com",
            port:     port,
            user:     user,
            password: password,

            ssl_options[:key].to_sym => ssl_options[:value],
          },
        }
      end
    end
  end

  describe '#provider_inbound_mx' do
    subject(:result) { described_class.provider_inbound_mx(user, email, password, [mx_domain]) }

    let(:email)        { 'linus@zammad.com' }
    let(:password)     { 'some_pw' }
    let(:user)         { 'linus' }
    let(:domain)       { 'zammad.com' }
    let(:mx_domain)    { 'mx2.zammad.com' }

    let(:expected_result) do
      [
        provider_inbound_mx_setting(mx_domain, 993, user, password),
        provider_inbound_mx_setting(mx_domain, 993, email, password),
      ]
    end

    def provider_inbound_mx_setting(host, port, user, password)
      {
        adapter: 'imap',
        options: {
          host:     host,
          port:     port,
          ssl:      'ssl',
          user:     user,
          password: password,
        },
      }
    end

    it { is_expected.to eq(expected_result) }
  end

  describe '#provider_inbound_guess' do
    subject(:result) { described_class.provider_inbound_guess(user, email, password, domain) }

    let(:email)        { 'linus@zammad.com' }
    let(:password)     { 'some_pw' }
    let(:user)         { 'linus' }
    let(:domain)       { 'zammad.com' }

    let(:expected_result) do
      [
        provider_inbound_guess_setting('imap', 'mail.zammad.com', 993, user, password),
        provider_inbound_guess_setting('imap', 'mail.zammad.com', 993, email, password),
        provider_inbound_guess_setting('imap', 'imap.zammad.com', 993, user, password),
        provider_inbound_guess_setting('imap', 'imap.zammad.com', 993, email, password),
        provider_inbound_guess_setting('pop3', 'mail.zammad.com', 995, user, password),
        provider_inbound_guess_setting('pop3', 'mail.zammad.com', 995, email, password),
        provider_inbound_guess_setting('pop3', 'pop.zammad.com', 995, user, password),
        provider_inbound_guess_setting('pop3', 'pop.zammad.com', 995, email, password),
        provider_inbound_guess_setting('pop3', 'pop3.zammad.com', 995, user, password),
        provider_inbound_guess_setting('pop3', 'pop3.zammad.com', 995, email, password),
      ]
    end

    def provider_inbound_guess_setting(adapter, host, port, user, password)
      {
        adapter: adapter,
        options: {
          host:     host,
          port:     port,
          ssl:      'ssl',
          user:     user,
          password: password,
        }
      }
    end

    it { is_expected.to eq(expected_result) }
  end

  describe '#provider_outbound_mx' do
    subject(:result) { described_class.provider_outbound_mx(user, email, password, [mx_domain]) }

    let(:email)        { 'linus@zammad.com' }
    let(:password)     { 'some_pw' }
    let(:user)         { 'linus' }
    let(:domain)       { 'zammad.com' }
    let(:mx_domain)    { 'mx.zammad.com' }

    let(:expected_result) do
      [
        provider_outbound_mx_setting(mx_domain, 465, true, user, password),
        provider_outbound_mx_setting(mx_domain, 465, true, email, password),
        provider_outbound_mx_setting(mx_domain, 587, nil, user, password),
        provider_outbound_mx_setting(mx_domain, 587, nil, email, password),
        provider_outbound_mx_setting(mx_domain, 25, true, user, password),
        provider_outbound_mx_setting(mx_domain, 25, true, email, password),
      ]
    end

    def provider_outbound_mx_setting(host, port, with_ssl, user, password)
      options = {
        host:     host,
        port:     port,
        user:     user,
        password: password,
      }

      if with_ssl.present?
        options[:start_tls] = with_ssl
      end

      {
        adapter: 'smtp',
        options: options,
      }
    end

    it { is_expected.to eq(expected_result) }
  end

  describe '#provider_outbound_guess' do
    subject(:result) { described_class.provider_outbound_guess(user, email, password, domain) }

    let(:email)        { 'linus@zammad.com' }
    let(:password)     { 'some_pw' }
    let(:user)         { 'linus' }
    let(:domain)       { 'zammad.com' }

    let(:expected_result) do
      [
        provider_outbound_guess_setting('mail.zammad.com', 465, user, password),
        provider_outbound_guess_setting('mail.zammad.com', 465, email, password),
        provider_outbound_guess_setting('smtp.zammad.com', 465, user, password),
        provider_outbound_guess_setting('smtp.zammad.com', 465, email, password),
        provider_outbound_guess_setting('mail.zammad.com', 587, user, password),
        provider_outbound_guess_setting('mail.zammad.com', 587, email, password),
        provider_outbound_guess_setting('smtp.zammad.com', 587, user, password),
        provider_outbound_guess_setting('smtp.zammad.com', 587, email, password),
        provider_outbound_guess_setting('mail.zammad.com', 25, user, password),
        provider_outbound_guess_setting('mail.zammad.com', 25, email, password),
        provider_outbound_guess_setting('smtp.zammad.com', 25, user, password),
        provider_outbound_guess_setting('smtp.zammad.com', 25, email, password),
      ]
    end

    def provider_outbound_guess_setting(host, port, user, password)
      {
        adapter: 'smtp',
        options: {
          host:      host,
          port:      port,
          start_tls: true,
          user:      user,
          password:  password,
        }
      }
    end

    it { is_expected.to eq(expected_result) }
  end
end
