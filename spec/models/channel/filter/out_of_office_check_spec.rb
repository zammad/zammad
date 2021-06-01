# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::OutOfOfficeCheck, type: :channel_filter do
  describe '.run' do
    let(:mail_hash) { Channel::EmailParser.new.parse(<<~RAW.chomp) }
      From: me@example.com
      To: customer@example.com
      Subject: #{subject_line}
      #{client_headers}

      Some Text
    RAW

    let(:subject_line) { 'Lorem ipsum dolor' }

    shared_examples 'regular message' do
      it 'sets x-zammad-out-of-office header to false' do
        expect { filter(mail_hash) }
          .to change { mail_hash[:'x-zammad-out-of-office'] }.to(false)
      end
    end

    shared_examples 'auto-response' do
      it 'sets x-zammad-out-of-office header to true' do
        expect { filter(mail_hash) }
          .to change { mail_hash[:'x-zammad-out-of-office'] }.to(true)
      end
    end

    context 'for regular messages' do
      context 'with MS/Exchange-style headers' do
        let(:client_headers) { 'X-MS-Exchange-Inbox-Rules-Loop: aaa.bbb@example.com' }

        include_examples 'regular message'
      end

      context 'with Zimbra-style headers' do
        let(:client_headers) { 'X-Mailer: Zimbra 7.1.3_GA_3346' }

        include_examples 'regular message'
      end

      context 'with no additional headers (Cloud- & Gmail-style)' do
        let(:client_headers) { '' }

        include_examples 'regular message'
      end
    end

    context 'for auto-response messages' do
      context 'with MS/Exchange-style headers' do
        let(:client_headers) { <<~HEAD.chomp }
          X-MS-Has-Attach:
          X-Auto-Response-Suppress: All
          X-MS-Exchange-Inbox-Rules-Loop: aaa.bbb@example.com
          X-MS-TNEF-Correlator:
          x-olx-disclaimer: Done
          x-tm-as-product-ver: SMEX-11.0.0.4179-8.000.1202-21706.006
          x-tm-as-result: No--39.689200-0.000000-31
          x-tm-as-user-approved-sender: Yes
          x-tm-as-user-blocked-sender: No
        HEAD

        include_examples 'auto-response'
      end

      context 'with Zimbra-style headers' do
        let(:client_headers) { <<~HEAD.chomp }
          Auto-Submitted: auto-replied (zimbra; vacation)
          Precedence: bulk
          X-Mailer: Zimbra 7.1.3_GA_3346
        HEAD

        include_examples 'auto-response'
      end

      context 'with Cloud-style headers' do
        let(:client_headers) { <<~HEAD.chomp }
          Auto-submitted: auto-replied; owner-email="me@example.com"
        HEAD

        include_examples 'auto-response'
      end

      context 'with Gmail-style headers' do
        let(:subject_line) { 'vacation: Lorem ipsum dolor' }
        let(:client_headers) { <<~HEAD.chomp }
          Precedence: bulk
          X-Autoreply: yes
          Auto-Submitted: auto-replied
        HEAD

        include_examples 'auto-response'
      end
    end
  end
end
