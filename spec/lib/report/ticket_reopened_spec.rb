# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/report_examples'

RSpec.describe Report::TicketReopened, searchindex: true do
  # report profile in expert mode (#6527)
  let(:expert_selector) do
    {
      'operator'   => 'OR',
      'conditions' => [
        { 'name' => 'ticket.priority_id', 'operator' => 'is', 'value' => [Ticket::Priority.lookup(name: '2 normal').id] },
        { 'name' => 'ticket.priority_id', 'operator' => 'is', 'value' => [Ticket::Priority.lookup(name: '3 high').id] },
      ],
    }
  end

  # closed, reopened and merged afterwards, so it must not show up in reopened reports (#6527)
  let(:ticket_reopened_merged) do
    travel_to DateTime.new 2015, 10, 29, 9, 30
    ticket = create(:ticket,
                    group:         group_1,
                    customer:      customer,
                    state_name:    'closed',
                    priority_name: '2 normal',
                    close_at:      Time.zone.now)

    travel 10.minutes
    ticket.update!(state: Ticket::State.lookup(name: 'open'))

    travel 10.minutes
    ticket.update!(state: Ticket::State.lookup(name: 'merged'))

    travel_back
    ticket
  end

  include_examples 'with report examples'

  describe '.aggs' do
    before do
      ticket_reopened_merged
    end

    it 'gets monthly aggregated results excluding merged tickets' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        interval:    'month',
        selector:    {},
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
    end

    it 'gets monthly aggregated results excluding merged tickets in expert mode' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        interval:    'month',
        selector:    expert_selector,
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
    end

    it 'gets monthly aggregated results with high priority' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        interval:    'month',
        selector:    {
          'ticket.priority_id' => {
            'operator' => 'is',
            'value'    => [Ticket::Priority.lookup(name: '3 high').id],
          }
        }
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
    end

    it 'gets monthly aggregated results with not high priority' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        interval:    'month',
        selector:    {
          'ticket.priority_id' => {
            'operator' => 'is not',
            'value'    => [Ticket::Priority.lookup(name: '3 high').id],
          }
        },
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end
  end

  describe '.items' do
    before do
      ticket_reopened_merged
    end

    it 'gets items in year range excluding merged tickets' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {},
      )

      expect(result).to match_tickets ticket_5
    end

    it 'gets items in year range excluding merged tickets in expert mode' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    expert_selector,
      )

      expect(result).to match_tickets ticket_5
    end

    it 'gets items in year range with high priority' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'ticket.priority_id' => {
            'operator' => 'is',
            'value'    => [Ticket::Priority.lookup(name: '3 high').id],
          }
        },
      )

      expect(result).to match_tickets ticket_5
    end

    it 'gets items in year range with not high priority' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'ticket.priority_id' => {
            'operator' => 'is not',
            'value'    => [Ticket::Priority.lookup(name: '3 high').id],
          }
        },
      )

      expect(result).to match_tickets []
    end
  end
end
