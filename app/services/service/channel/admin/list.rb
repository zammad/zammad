# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::Channel::Admin
  class List < Service::Base
    def initialize(area:)
      @area = area
    end

    def execute
      Channel
        .in_area(@area)
        .reorder(:id)
    end
  end
end
