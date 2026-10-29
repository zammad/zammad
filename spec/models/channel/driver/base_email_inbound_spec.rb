# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::BaseEmailInbound, :aggregate_failures do
  describe '#fetch' do
    subject(:driver) { driver_class.new }

    let(:channel) { create(:email_channel) }

    # Stands in for the connection and the mailbox of a real driver, with the messages given as options.
    let(:driver_class) do
      Class.new(described_class) do
        def setup_connection(_options, check: false); end

        def messages_iterator(_keep_on_server, options)
          [options[:messages], options[:messages].size]
        end

        def fetch_single_message(msg, count, count_all)
          process_message(msg, count, count_all) || Channel::Driver::BaseEmailInbound::MessageResult.new(success: true)
        end
      end
    end

    let(:poison_mail) { "From: foo@example.com\nTo: support@example.com\nSubject: Poison\n\nLorem ipsum dolor" }
    let(:good_mail)   { "From: foo@example.com\nTo: support@example.com\nSubject: Good\n\nLorem ipsum dolor" }

    before do
      allow(driver).to receive(:_process).and_wrap_original do |original, channel, msg|
        raise 'content parser gone' if msg.include?('Subject: Poison')

        original.call(channel, msg)
      end

      allow_any_instance_of(Channel::EmailParser::ErrorTicket).to receive(:create!).and_raise('database gone')
    end

    it 'fetches the remaining messages after one that could become no ticket at all and reports it' do
      result = nil

      expect { result = driver.fetch({ messages: [poison_mail, good_mail] }, channel) }
        .to change(Ticket, :count).by(1)

      expect(Ticket.last.title).to eq('Good')
      expect(result).to include(
        result:  'error',
        fetched: 1,
        notice:  include('message 1/2 could not be processed and stays on the server', 'database gone'),
      )
    end
  end
end
