# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SetMailSSLDefault, :aggregate_failures, type: :db_migration do
  let(:email_notification_smtp)        { create(:email_notification_channel, :smtp) }
  let(:email_notification_smtp_nonssl) { create(:email_notification_channel, :smtp, outbound_port: 25) }
  let(:email_notification_sendmail)    { create(:email_notification_channel, :sendmail) }
  let(:email_channel_smtp_imap)        { create(:email_channel, :smtp, :imap) }
  let(:email_channel_smtp_nonssl)      { create(:email_channel, :smtp, outbound_port: 25) }
  let(:email_channel_sendmail_pop3)    { create(:email_channel, :sendmail, :pop3) }
  let(:email_gmail)                    { create(:google_channel) }
  let(:email_microsoft)                { create(:microsoft365_channel) }

  before do
    [
      email_notification_smtp, email_notification_sendmail,
      email_channel_smtp_imap, email_channel_sendmail_pop3,
      email_channel_smtp_nonssl, email_notification_smtp_nonssl,
      email_gmail, email_microsoft
    ].each do |elem|
      if elem.options[:outbound][:options]
        elem.options[:outbound][:options].delete :ssl_verify

        if elem.options[:outbound][:adapter] == 'smtp'
          elem.options[:outbound][:options].delete :ssl
        end
      end

      if elem.options[:inbound]
        elem.options[:inbound][:options].delete :ssl_verify
      end
      elem.save!
    end

    migrate
  end

  it 'sets Oauth channels to verify SSL' do
    [email_gmail, email_microsoft].each do |elem|
      expect(elem.reload.options).to include(
        inbound:  include(
          options: include(ssl_verify: true)
        ),
        outbound: include(
          options: include(ssl_verify: true)
        )
      )
    end
  end

  it 'sets custom channels to not verify SSL' do
    expect(email_channel_smtp_imap.reload.options).to include(
      inbound:  include(
        adapter: 'imap',
        options: include(ssl_verify: false)
      ),
      outbound: include(
        adapter: 'smtp',
        options: include(ssl_verify: false)
      )
    )

    expect(email_channel_sendmail_pop3.reload.options).to include(
      outbound: include(
        adapter: 'sendmail',
      ),
      inbound:  include(
        adapter: 'pop3',
        options: include(ssl_verify: false)
      )
    )

    expect(email_channel_sendmail_pop3.options[:outbound]).not_to have_key('options')

    expect(email_notification_smtp.reload.options).to include(
      outbound: include(
        adapter: 'smtp',
        options: include(ssl_verify: false)
      )
    )

    expect(email_notification_sendmail.options[:outbound]).not_to have_key('options')
  end
end
