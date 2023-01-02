# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/report_examples'

RSpec.describe Report::TicketMoved, searchindex: true do
  include_examples 'with report examples'

  describe '.aggs' do
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
        params:      {
          type: 'in',
        },
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end

    it 'gets monthly aggregated results in users group' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        interval:    'month',
        selector:    {
          'ticket.group_id' => {
            'operator' => 'is',
            'value'    => [Group.lookup(name: 'Users').id],
          }
        },
        params:      {
          type: 'in',
        },
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
    end

    it 'gets monthly aggregated results not in merged state and outgoing' do
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
        params:      {
          type: 'out',
        },
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end

    it 'gets monthly aggregated results in users group and outgoing' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        interval:    'month',
        selector:    {
          'ticket.group_id' => {
            'operator' => 'is',
            'value'    => [Group.lookup(name: 'Users').id],
          }
        },
        params:      {
          type: 'out',
        },
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
    end

  end

  describe '.items' do
    it 'gets items in year range in users group' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'ticket.group_id' => {
            'operator' => 'is',
            'value'    => [Group.lookup(name: 'Users').id],
          }
        },
        params:      {
          type: 'in',
        },
      )

      expect(result).to match_tickets ticket_1
    end

    it 'gets items in year range not merged and outgoing' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'ticket_state.name' => {
            'operator' => 'is not',
            'value'    => 'merged',
          }
        }, # ticket selector to get only a collection of tickets
        params:      {
          type: 'out',
        },
      )

      expect(result).to match_tickets []
    end

    it 'gets items in year range in users group and outgoing' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'ticket.group_id' => {
            'operator' => 'is',
            'value'    => [Group.lookup(name: 'Users').id],
          }
        },
        params:      {
          type: 'out',
        },
      )

      expect(result).to match_tickets ticket_2
    end

  end
end
