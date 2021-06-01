# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Escalation::PeriodWorkingMinutes do
  let(:instance)   { described_class.new start_time, end_time, ticket, biz }
  let(:start_time) { 1.week.ago }
  let(:end_time)   { 1.day.ago }
  let(:ticket)     { create(:ticket) }
  let(:calendar)   { create(:calendar, :'24/7') }
  let(:biz)        { calendar.biz breaks: Escalation::TicketBizBreak.new(ticket, calendar).biz_breaks }

  describe '#period_working_minutes' do
    subject(:result) { instance.send(:period_working_minutes) }

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

    context 'when timeframe takes whole ticket life' do
      let(:start_time) { ticket.created_at }
      let(:end_time)   { ticket.close_at + 2.hours }

      it { is_expected.to be 90 }
    end

    context 'when timeframe starts before and ends after ticket life' do
      let(:start_time) { ticket.created_at - 1.week }
      let(:end_time)   { ticket.close_at + 1.week }

      it { is_expected.to be 90 }
    end

    context 'when timeframe starts in the middle of ticket life' do
      let(:start_time) { ticket.created_at + 30.minutes }
      let(:end_time)   { ticket.close_at }

      it { is_expected.to be 60 }
    end

    context 'when timeframe end in the middle of ticket life' do
      let(:start_time) { ticket.created_at }
      let(:end_time)   { ticket.created_at + 30.minutes }

      it { is_expected.to be 30 }
    end
  end

  describe '#timeframe_start' do
    subject(:result) { instance.send(:timeframe_start) }

    context 'when start_time is early' do
      it { is_expected.to eq ticket.created_at }
    end

    context 'when start_time is later than #created_at' do
      let(:start_time) { 1.week.from_now }

      it { is_expected.to eq start_time }
    end
  end

  describe '#timeframe_end' do
    subject(:result) { instance.send(:timeframe_end) }

    context 'when end_time is late' do
      let(:end_time) { 1.week.from_now }

      before do
        ticket.update! close_at: 1.day.from_now
      end

      it { is_expected.to eq ticket.close_at }
    end

    context 'when end_time is before closing' do
      let(:end_time) { 1.week.from_now }

      before do
        ticket.update! close_at: 2.weeks.from_now
      end

      it { is_expected.to eq end_time }
    end

    context 'when #close_at is not set' do
      let(:end_time) { 1.week.ago }

      it { is_expected.to eq end_time }
    end
  end
end
