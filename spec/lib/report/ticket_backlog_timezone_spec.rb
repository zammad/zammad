# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Report::TicketBacklog, 'timezone', searchindex: true do
  let(:today) { Time.zone.parse('2019-03-15T08:00:00Z') }

  before do
    travel_to today.midday
    Ticket.destroy_all
    create(:ticket, created_at: today.midday)
    create(:ticket, created_at: today.midday + 2.hours)
    create(:ticket, created_at: today.midday + 2.hours)
    create(:ticket, created_at: today.midday + 10.hours, state: Ticket::State.lookup(name: 'closed'))
    create(:ticket, created_at: today.midday + 11.hours)
    create(:ticket, created_at: today.midday - 11.hours)
    create(:ticket, created_at: Time.zone.parse('2019-02-28T23:30:00Z'))
    create(:ticket, created_at: Time.zone.parse('2019-03-01T00:30:00Z'))
    create(:ticket, created_at: Time.zone.parse('2019-03-31T23:30:00Z'))
    create(:ticket, created_at: Time.zone.parse('2019-04-01T00:30:00Z'))

    searchindex_model_reload([Ticket])
  end

  def self.series(size, counts = {})
    Array.new(size) { |index| counts.fetch(index, 0) }
  end

  # Mirrors ReportsController#time_range, which computes the range in the requested timezone.
  def range_for(time_range, year:, month: nil, day: nil)
    lambda do |timezone|
      Time.use_zone(timezone) do
        case time_range
        when 'day'
          date = Date.new(year, month, day)
          [date.beginning_of_day, date.end_of_day, 'hour']
        when 'month'
          date = Date.new(year, month, 1)
          [date.beginning_of_day, date.end_of_month.end_of_day, 'day']
        else
          date = Date.new(year, 1, 1)
          [date.beginning_of_day, date.end_of_year.end_of_day, 'month']
        end
      end
    end
  end

  shared_examples 'aggregating in timezone' do |timezone, created:, closed:, backlog:|
    context "with timezone #{timezone}" do
      let(:aggs_params) do
        range_start, range_end, interval = range.call(timezone)

        { range_start:, range_end:, interval:, selector: {}, timezone: }
      end

      it 'aggregates created, closed and backlog tickets per interval', :aggregate_failures do
        expect(Report::TicketGenericTime.aggs(**aggs_params, params: { field: 'created_at' })).to eq(created)
        expect(Report::TicketGenericTime.aggs(**aggs_params, params: { field: 'close_at' })).to eq(closed)
        expect(described_class.aggs(aggs_params)).to eq(backlog)
      end
    end
  end

  context 'with day range 2019-03-15' do
    let(:range) { range_for('day', year: 2019, month: 3, day: 15) }

    include_examples 'aggregating in timezone', 'UTC',
                     created: series(24, 1 => 1, 12 => 1, 14 => 2, 22 => 1, 23 => 1),
                     closed:  series(24, 12 => 1),
                     backlog: series(24, 1 => 1, 14 => 2, 22 => 1, 23 => 1)

    include_examples 'aggregating in timezone', 'Europe/Berlin',
                     created: series(24, 2 => 1, 13 => 1, 15 => 2, 23 => 1),
                     closed:  series(24, 13 => 1),
                     backlog: series(24, 2 => 1, 15 => 2, 23 => 1)

    include_examples 'aggregating in timezone', 'America/Chicago',
                     created: series(24, 7 => 1, 9 => 2, 17 => 1, 18 => 1),
                     closed:  series(24, 7 => 1),
                     backlog: series(24, 9 => 2, 17 => 1, 18 => 1)

    include_examples 'aggregating in timezone', 'Australia/Melbourne',
                     created: series(24, 12 => 1, 23 => 1),
                     closed:  series(24, 23 => 1),
                     backlog: series(24, 12 => 1)
  end

  context 'with month range 2019-03' do
    let(:range) { range_for('month', year: 2019, month: 3) }

    include_examples 'aggregating in timezone', 'UTC',
                     created: series(31, 0 => 1, 14 => 6, 30 => 1),
                     closed:  series(31, 14 => 1),
                     backlog: series(31, 0 => 1, 14 => 5, 30 => 1)

    include_examples 'aggregating in timezone', 'Europe/Berlin',
                     created: series(31, 0 => 2, 14 => 5, 15 => 1),
                     closed:  series(31, 14 => 1),
                     backlog: series(31, 0 => 2, 14 => 4, 15 => 1)

    include_examples 'aggregating in timezone', 'America/Chicago',
                     created: series(31, 13 => 1, 14 => 5, 30 => 2),
                     closed:  series(31, 14 => 1),
                     backlog: series(31, 13 => 1, 14 => 4, 30 => 2)

    include_examples 'aggregating in timezone', 'Australia/Melbourne',
                     created: series(31, 0 => 2, 14 => 2, 15 => 4),
                     closed:  series(31, 14 => 1),
                     backlog: series(31, 0 => 2, 14 => 1, 15 => 4)
  end

  context 'with month range 2019-02' do
    let(:range) { range_for('month', year: 2019, month: 2) }

    include_examples 'aggregating in timezone', 'UTC',
                     created: series(28, 27 => 1),
                     closed:  series(28),
                     backlog: series(28, 27 => 1)

    include_examples 'aggregating in timezone', 'Europe/Berlin',
                     created: series(28),
                     closed:  series(28),
                     backlog: series(28)

    include_examples 'aggregating in timezone', 'America/Chicago',
                     created: series(28, 27 => 2),
                     closed:  series(28),
                     backlog: series(28, 27 => 2)

    include_examples 'aggregating in timezone', 'Australia/Melbourne',
                     created: series(28),
                     closed:  series(28),
                     backlog: series(28)
  end

  context 'with month range 2019-04' do
    let(:range) { range_for('month', year: 2019, month: 4) }

    include_examples 'aggregating in timezone', 'UTC',
                     created: series(30, 0 => 1),
                     closed:  series(30),
                     backlog: series(30, 0 => 1)

    include_examples 'aggregating in timezone', 'Europe/Berlin',
                     created: series(30, 0 => 2),
                     closed:  series(30),
                     backlog: series(30, 0 => 2)

    include_examples 'aggregating in timezone', 'America/Chicago',
                     created: series(30),
                     closed:  series(30),
                     backlog: series(30)

    include_examples 'aggregating in timezone', 'Australia/Melbourne',
                     created: series(30, 0 => 2),
                     closed:  series(30),
                     backlog: series(30, 0 => 2)
  end

  context 'with year range 2019' do
    let(:range) { range_for('year', year: 2019) }

    include_examples 'aggregating in timezone', 'UTC',
                     created: series(12, 1 => 1, 2 => 8, 3 => 1),
                     closed:  series(12, 2 => 1),
                     backlog: series(12, 1 => 1, 2 => 7, 3 => 1)

    include_examples 'aggregating in timezone', 'Europe/Berlin',
                     created: series(12, 2 => 8, 3 => 2),
                     closed:  series(12, 2 => 1),
                     backlog: series(12, 2 => 7, 3 => 2)

    include_examples 'aggregating in timezone', 'America/Chicago',
                     created: series(12, 1 => 2, 2 => 8),
                     closed:  series(12, 2 => 1),
                     backlog: series(12, 1 => 2, 2 => 7)

    include_examples 'aggregating in timezone', 'Australia/Melbourne',
                     created: series(12, 2 => 8, 3 => 2),
                     closed:  series(12, 2 => 1),
                     backlog: series(12, 2 => 7, 3 => 2)
  end
end
