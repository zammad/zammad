# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Escalation
  class PeriodWorkingMinutes
    def initialize(start_time, end_time, ticket, biz)
      @start_time = start_time
      @end_time   = end_time
      @ticket     = ticket
      @biz        = biz
    end

    def period_working_minutes
      @biz.within(timeframe_start, timeframe_end).in_minutes
    end

    private

    def timeframe_start
      [@ticket.created_at, @start_time].compact.max
    end

    def timeframe_end
      [@ticket.close_at, @end_time].compact.min
    end
  end
end
