# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Escalation::DestinationTime do
  let(:instance)   { described_class.new start_time, span, biz }
  let(:start_time) { Time.current }
  let(:span)       { 30 }
  let(:ticket)     { create(:ticket) }
  let(:calendar)   { create(:calendar, :'24/7') }
  let(:biz)        { calendar.biz breaks: Escalation::TicketBizBreak.new(ticket, calendar).biz_breaks }

  describe '#destination_time' do
    subject(:result) { instance.send(:destination_time) }

    before do
      freeze_time
      ticket.update! state: Ticket::State.lookup(name: 'new')
      travel 1.hour
      ticket.update! state: Ticket::State.lookup(name: 'open')
      travel 30.minutes
      ticket.update! state: Ticket::State.lookup(name: 'pending close')
      travel 30.minutes
      ticket.update! state: Ticket::State.lookup(name: 'closed'), close_at: Time.current
    end

    context 'when whole span fits' do
      let(:start_time) { ticket.created_at }

      it { is_expected.to eq 90.minutes.ago }
    end

    context 'when timeframe starts before and ends after ticket life' do
      let(:start_time) { ticket.created_at + 75.minutes }

      it { is_expected.to eq 15.minutes.from_now }
    end

    context 'when timeframe starts in the middle of ticket life' do
      let(:start_time) { Time.current }

      it { is_expected.to eq 30.minutes.from_now }
    end
  end
end
