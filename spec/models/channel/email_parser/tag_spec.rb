# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser > Tags', aggregate_failures: true, type: :model do
  context 'when tags are given as headers' do
    let(:channel) { create(:channel, options: { inbound: { trusted: true } }) }

    let(:raw_email) { <<~RAW.chomp }
      From: Max Smith <customer@example.com>
      To: myzammad@example.com
      Subject: test sender name update 2
      X-Zammad-Ticket-Tags: test1, test2, test3

      Some Text
    RAW

    it 'adds tags to the ticket' do
      ticket, = Channel::EmailParser.new.process(channel, raw_email)

      expect(ticket).to be_a Ticket
      expect(ticket.tag_list).to include('test1', 'test2', 'test3')
    end
  end
end
