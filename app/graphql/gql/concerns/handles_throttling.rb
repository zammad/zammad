# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concerns::HandlesThrottling
  extend ActiveSupport::Concern

  included do
    def throttle!(limit:, period:, by_identifier: nil)
      ip = context[:controller].request.remote_ip

      OperationsRateLimiter
        .new(limit:, period:, operation: self.class.name)
        .ensure_within_limits!(by_ip: ip, by_identifier: by_identifier)
    end
  end
end
