# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/report_examples'

RSpec.describe Report::TicketMerged, searchindex: true do
  include_examples 'with report examples'

  describe '.aggs' do
    it 'gets monthly aggregated results in merged state' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        interval:    'month',
        selector:    {},
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0]
    end

    it 'gets daily aggregated results in merged state' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-11-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-01T00:00:00Z'),
        interval:    'day',
        selector:    {},
      )

      expected = Array.new(30, 0) # 30 days in November
      expected[1] = 1 # ticket exists on November 2nd

      expect(result).to eq expected
    end
  end

  describe '.items' do
    it 'gets items in year range in merged state' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {},
      )

      expect(result).to match_tickets ticket_8
    end
  end
end
