# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket: #current_state_color' do # rubocop:disable RSpec/DescribeClass
  let(:ticket) { create(:ticket) }

  shared_examples 'returns correct hex color code' do |expected_color_code|
    it "returns correct hex color code #{expected_color_code}" do
      expect(ticket.current_state_color).to eq(expected_color_code)
    end
  end

  context 'when state is open' do
    before do
      ticket.update!(state: Ticket::State.find_by(name: 'open'))
    end

    include_examples 'returns correct hex color code', '#faab00'
  end

  context 'when state is new' do
    before do
      ticket.update!(state: Ticket::State.find_by(name: 'new'))
    end

    include_examples 'returns correct hex color code', '#faab00'
  end

  context 'when state is closed' do
    before do
      ticket.update!(state: Ticket::State.find_by(name: 'closed'))
    end

    include_examples 'returns correct hex color code', '#38ad69'
  end

  context 'when state is pending reminder' do
    before do
      ticket.update!(state: Ticket::State.find_by(name: 'open'))
    end

    context 'when pending time is reached' do
      before do
        ticket.update!(state: Ticket::State.find_by(name: 'pending reminder'), pending_time: 1.day.ago)
      end

      include_examples 'returns correct hex color code', '#faab00'
    end

    context 'when pending time is not reached' do
      before do
        ticket.update!(state: Ticket::State.find_by(name: 'pending reminder'), pending_time: 1.day.since)
      end

      include_examples 'returns correct hex color code', '#000000'
    end
  end

  context 'when ticket is escalated' do
    before do
      ticket.update!(state: Ticket::State.find_by(name: 'pending reminder'), escalation_at: 1.day.since)
    end

    include_examples 'returns correct hex color code', '#000000'
  end
end
