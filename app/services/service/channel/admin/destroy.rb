# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::Channel::Admin
  class Destroy < Service::Base
    def initialize(area:, channel_id:)
      @area       = area
      @channel_id = channel_id
    end

    def execute
      Channel
        .in_area(@area)
        .find(@channel_id)
        .destroy!
    end
  end
end
