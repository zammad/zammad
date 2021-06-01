# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Escalation
  class DestinationTime
    def initialize(start_time, span, biz)
      @start_time = start_time
      @span       = span
      @biz        = biz
    end

    def destination_time
      @biz.time(@span, :minutes).after(@start_time)
    end
  end
end
