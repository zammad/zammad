# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.shared_examples 'TicketSelector2Sql' do
  context 'when relative time range is selected in ticket selector' do
    def get_condition(operator, range)
      {
        'ticket.created_at' => {
          operator: operator,
          range:    range, # minute|hour|day|month|
          value:    '10',
        },
      }
    end

    before do
      freeze_time
    end

    it 'calculates proper time interval, when operator is within last relative' do
      condition = get_condition('within last (relative)', 'minute')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.minutes.ago, Time.zone.now])
    end

    it 'calculates proper time interval, when operator is within next relative' do
      condition = get_condition('within next (relative)', 'hour')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([Time.zone.now, 10.hours.from_now])
    end

    it 'calculates proper time interval, when operator is before (relative)' do
      condition = get_condition('before (relative)', 'day')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.days.ago])
    end

    it 'calculates proper time interval, when operator is after (relative)' do
      condition = get_condition('after (relative)', 'week')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.weeks.from_now])
    end

    it 'calculates proper time interval, when operator is till (relative)' do
      condition = get_condition('till (relative)', 'month')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.months.from_now])
    end

    it 'calculates proper time interval, when operator is from (relative)' do
      condition = get_condition('from (relative)', 'year')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.years.ago])
    end
  end
end
