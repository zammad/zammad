# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Escalation::TicketBizBreak, time_zone: 'Europe/Berlin' do
  let(:ticket)   { create(:ticket) }
  let(:calendar) { create(:calendar) }
  let(:instance) { described_class.new(ticket, calendar) }

  describe '#biz_breaks' do
    let(:result) { instance.biz_breaks }

    context 'when ticket history is empty' do
      it { expect(result).to be_a(Hash) }
      it { expect(result).to be_empty }
    end

    context 'when ticket is opened' do
      before do
        travel 15.minutes
        ticket.update! state: Ticket::State.lookup(name: 'open')
      end

      it { expect(result).to be_a(Hash) }
      it { expect(result).to be_empty }
    end

    context 'when ticket was opened and closed' do
      before do
        travel 15.minutes
        ticket.update! state: Ticket::State.lookup(name: 'open')
        travel 15.minutes
        ticket.update! state: Ticket::State.lookup(name: 'closed')
      end

      it { expect(result).to be_a(Hash) }
      it { expect(result).to be_empty }
    end

    context 'when ticket was started in non-escalated state and closed' do
      let(:ticket) { create(:ticket, state: Ticket::State.lookup(name: 'pending reminder')) }

      before do
        travel_to Time.current.noon
        ticket
        travel 15.minutes
        ticket.update! state: Ticket::State.lookup(name: 'closed')
      end

      it { expect(result).to be_a(Hash) }
      it { expect(result).to be_one }
    end

    context 'when ticket was suspended and reopened multiple times' do
      before do
        travel_to Time.current.noon

        ticket.update! state: Ticket::State.lookup(name: 'open')
        travel 15.minutes
        ticket.update! state: Ticket::State.lookup(name: 'pending reminder')
        travel 15.minutes
        ticket.update! state: Ticket::State.lookup(name: 'open')
        travel 15.minutes
        ticket.update! state: Ticket::State.lookup(name: 'pending close')
        travel 15.minutes
        ticket.update! state: Ticket::State.lookup(name: 'closed')
      end

      let(:first_value) { result.values.first }

      it { expect(result).to be_a(Hash) }
      it { expect(result.keys).to be_one }
      it { expect(result.keys.first).to be_a(Date) }
      it { expect(result.keys.first).to eq(Time.current.to_date) }
      it { expect(first_value).to be_a(Hash) }
      it { expect(first_value.keys).to eq %w[12:15 12:45] }
      it { expect(first_value['12:15']).to eq '12:30' }
      it { expect(first_value['12:45']).to eq '13:00' }
    end

    context 'when ticket was suspended over midnight in UTC', time_zone: 'UTC' do
      before do
        travel_to Time.current.change(month: 11).utc.midnight
        travel(-15.minutes)

        ticket.update! state: Ticket::State.lookup(name: 'pending reminder')
        travel 30.minutes
        ticket.update! state: Ticket::State.lookup(name: 'open')
      end

      let(:first_value) { result.values.first }

      it { expect(result.keys).to be_one }
      it { expect(result.keys.first).to be_a(Date) }
      it { expect(result.keys.first).to eq(Time.current.to_date) }
      it { expect(first_value).to be_a(Hash) }
      it { expect(first_value.keys).to eq %w[00:45] }
      it { expect(first_value['00:45']).to eq '01:15' }
    end

    context 'when ticket was suspended over midnight in timezone' do
      before do
        travel_to Time.current.midnight
        travel(-15.minutes)
        ticket.update! state: Ticket::State.lookup(name: 'pending reminder')
        travel 1.hour
        ticket.update! state: Ticket::State.lookup(name: 'open')
      end

      let(:first_value) { result.values.first }
      let(:second_value) { result.values.second }

      it { expect(result.keys.count).to be(2) }
      it { expect(result.keys).to eq [Time.current.yesterday.to_date, Time.current.to_date] }
      it { expect(first_value).to be_a(Hash) }
      it { expect(first_value.keys).to eq %w[23:45] }
      it { expect(first_value['23:45']).to eq '24:00' }
      it { expect(second_value).to be_a(Hash) }
      it { expect(second_value.keys).to eq %w[00:00] }
      it { expect(second_value['00:00']).to eq '00:45' }
    end

    context 'when ticket was suspended for multiple days' do
      before do
        travel_to Time.current.noon
        ticket.update! state: Ticket::State.lookup(name: 'pending reminder')
        travel 5.days
        ticket.update! state: Ticket::State.lookup(name: 'open')
      end

      let(:first_value) { result.values.first }
      let(:second_value) { result.values.second }

      it { expect(result.keys.count).to be(6) }
      it { expect(result.keys).to eq ((Time.current - 5.days).to_date..Time.current).to_a }
      it { expect(result.values[0].keys).to eq %w[12:00] }
      it { expect(result.values[0]['12:00']).to eq '24:00' }
      it { expect(result.values[1].keys).to eq %w[00:00] }
      it { expect(result.values[1]['00:00']).to eq '24:00' }
      it { expect(result.values[2].keys).to eq %w[00:00] }
      it { expect(result.values[2]['00:00']).to eq '24:00' }
      it { expect(result.values[3].keys).to eq %w[00:00] }
      it { expect(result.values[3]['00:00']).to eq '24:00' }
      it { expect(result.values[4].keys).to eq %w[00:00] }
      it { expect(result.values[4]['00:00']).to eq '24:00' }
      it { expect(result.values[5].keys).to eq %w[00:00] }
      it { expect(result.values[5]['00:00']).to eq '12:00' }
    end
  end

  describe '#history_list_states' do
    let(:result) { instance.send(:history_list_states) }

    it 'empty when history log is empty' do
      expect(result).to be_empty
    end

    it 'empty when history log has non-state records' do
      ticket.update! title: '2nd title'

      expect(result).to be_empty
    end

    it 'returns array of Hashes when history log has various records' do
      ticket.update! title: '2nd title', state: Ticket::State.lookup(name: 'open')

      expect(result.first).to be_a Hash
    end

    it 'lists changes in specific order when history log has various records' do
      ticket.update! title: 'title', state: Ticket::State.lookup(name: 'open')
      ticket.update! title: 'another title'
      ticket.update! state: Ticket::State.lookup(name: 'closed')

      expect(result.pluck('value_to')).to eq %w[open closed]
    end
  end

  describe '#ignored_escalation_state_names' do
    let(:result) { instance.send(:ignored_escalation_state_names) }

    it { expect(result).to be_a Array }
    it { expect(result).to be_all String }
    it { expect(result).to include 'closed' }
    it { expect(result).not_to include 'open' }
  end

  describe '#history_list_in_break' do
    let(:result) { instance.send(:history_list_in_break) }

    it { expect(result).to be_a Array }

    it 'empty history returns minutes in timeframe' do
      expect(result).to be_empty
    end

    context 'when contains 4 history points' do
      before do
        allow(instance).to receive(:history_list_states).and_return(history_list_4)
      end

      let(:history_list_4) do
        [
          mock_state_hash(ticket.created_at, nil, 'new'),
          mock_state_hash(ticket.created_at + 1.hour, 'new', 'open'),
          mock_state_hash(ticket.created_at + 90.minutes, 'open', 'pending close'),
          mock_state_hash(ticket.created_at + 2.hours, 'pending close', 'closed')
        ]
      end

      it 'returns one range' do
        expect(result).to be_one
      end

      it 'returns range from pending close' do
        expect(result.first.first['value_to']).to eq 'pending close'
      end

      it 'returns range to closed' do
        expect(result.first.second['value_to']).to eq 'closed'
      end

      it 'calls #range_on_break? thrice' do
        allow(instance).to receive(:range_on_break?)
        result
        expect(instance).to have_received(:range_on_break?).exactly(3).times
      end
    end
  end

  describe '#accumulate_breaks' do
    let(:input_a) { { Time.current.to_date => { '10:00' => '14:00' }, Time.current.tomorrow.to_date => { '10:00' => '14:05' } } }
    let(:input_b) { { Time.current.to_date => { '17:00' => '18:00' } } }
    let(:result)  { instance.send(:accumulate_breaks, [input_a, input_b]) }

    it { expect(result.keys).to eq [Time.current.to_date, Time.current.tomorrow.to_date] }
    it { expect(result[Time.current.to_date]).to eq({ '10:00' => '14:00', '17:00' => '18:00' }) }
    it { expect(result[Time.current.tomorrow.to_date]).to eq({ '10:00' => '14:05' }) }
  end

  describe '#history_range_to_breaks' do
    before { travel_to Time.current.noon }

    let(:result) { instance.send(:history_range_to_breaks, history_from, history_to) }

    context 'when fits in a single day' do
      let(:history_from) { mock_state_hash(ticket.created_at + 90.minutes, 'open', 'pending close') }
      let(:history_to) { mock_state_hash(ticket.created_at + 2.hours, 'pending close', 'closed') }

      it { expect(result).to be_a Hash }
      it { expect(result.keys).to eq [Time.current.to_date] }
      it { expect(result.values.first).to eq({ '13:30' => '14:00' }) }
    end

    context 'when spills over to multiple days' do
      let(:history_from) { mock_state_hash(ticket.created_at + 90.minutes, 'open', 'pending close') }
      let(:history_to) { mock_state_hash(ticket.created_at + 2.days, 'pending close', 'closed') }

      it { expect(result).to be_a Hash }
      it { expect(result.keys).to eq [Time.current.to_date, Time.current.tomorrow.to_date, (Time.current + 2.days).to_date] }
      it { expect(result.values.first).to eq({ '13:30' => '24:00' }) }
      it { expect(result.values.second).to eq({ '00:00' => '24:00' }) }
      it { expect(result.values.third).to eq({ '00:00' => '12:00' }) }
    end
  end

  describe '#mock_initial_state' do
    let(:result) { instance.send(:mock_initial_state) }

    it { expect(result).to have_key('created_at').and(have_key('value_to')) }

    context 'when ticket has no history' do
      it { expect(result).to include('created_at' => ticket.created_at) }
      it { expect(result).to include('value_to' => ticket.state.name) }
    end

    shared_context 'when ticket has state changes' do
      let(:initial_state_name) { 'pending reminder' }
      let(:ticket) { create :ticket, state: Ticket::State.lookup(name: initial_state_name) }

      before do
        freeze_time
        ticket
        travel timespan
        ticket.update! state: Ticket::State.lookup(name: 'closed')
      end
    end

    context 'when ticket has state changes later' do
      let(:timespan) { 30.minutes }

      include_examples 'when ticket has state changes'

      it { expect(result).to include('created_at' => ticket.created_at) }
      it { expect(result).to include('value_to' => initial_state_name) }
    end

    context 'when ticket has state changes at creation' do
      let(:timespan) { 0.minutes }

      include_examples 'when ticket has state changes'

      it { expect(result).to be_nil }
    end
  end

  def mock_state_hash(time, from, to)
    {
      'attribute'  => 'state',
      'created_at' => time,
      'value_from' => from,
      'value_to'   => to
    }
  end
end
