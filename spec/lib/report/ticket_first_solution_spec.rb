# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/report_examples'

RSpec.describe Report::TicketFirstSolution, searchindex: true do
  include_examples 'with report examples'

  describe '.aggs' do
    it 'gets monthly aggregated results' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        interval:    'month',
        selector:    {},
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 0]
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
        },
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
    end

    it 'gets monthly aggregated results not in merged state' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        interval:    'month',
        selector:    {
          'ticket_state.name' => {
            'operator' => 'is not',
            'value'    => 'merged',
          }
        },
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 0]
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

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0]
    end

    it 'gets weekly aggregated results' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-10-26T00:00:00Z'),
        range_end:   Time.zone.parse('2015-10-31T23:59:59Z'),
        interval:    'week',
        selector:    {},
      )

      expect(result).to eq [0, 0, 1, 0, 0, 1, 1]
    end

    it 'gets daily aggregated results' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-10-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-11-01T23:59:59Z'),
        interval:    'day',
        selector:    {},
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1]
    end

    it 'gets hourly aggregated results' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-10-28T00:00:00Z'),
        range_end:   Time.zone.parse('2015-10-28T23:59:59Z'),
        interval:    'hour',
        selector:    {},
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end
  end

  describe '.items' do
    it 'gets items in year range' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {},
      )
      expect(result).to match_tickets ticket_5, ticket_6, ticket_7
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
        }
      )

      expect(result).to match_tickets ticket_5
    end

    it 'gets items in year range not in merged state' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'ticket_state.name' => {
            'operator' => 'is not',
            'value'    => 'merged',
          }
        }
      )

      expect(result).to match_tickets ticket_5, ticket_6, ticket_7
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
        }
      )

      expect(result).to match_tickets ticket_6, ticket_7
    end

    it 'gets items in week range' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-10-26T00:00:00Z'),
        range_end:   Time.zone.parse('2015-11-01T23:59:59Z'),
        selector:    {}
      )

      expect(result).to match_tickets ticket_5, ticket_6, ticket_7
    end

    it 'gets items in day range' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-10-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-10-31T23:59:59Z'),
        selector:    {}
      )

      expect(result).to match_tickets ticket_5, ticket_6
    end

    it 'gets items in hour range' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-10-28T00:00:00Z'),
        range_end:   Time.zone.parse('2015-10-28T23:59:59Z'),
        interval:    'hour',
        selector:    {},
      )

      expect(result).to match_tickets ticket_5
    end
  end
end
