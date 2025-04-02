# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Service::Channel::Admin
  class Disable < Service::Base
    def initialize(area:, channel_id:)
      super()

      @area       = area
      @channel_id = channel_id
    end

    def execute
      Channel
        .in_area(@area)
        .find(@channel_id)
        .update!(active: false)
    end
  end
end
