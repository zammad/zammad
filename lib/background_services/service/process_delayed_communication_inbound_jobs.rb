# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Service
    class ProcessDelayedCommunicationInboundJobs < BaseDelayedJobs
      def self.queues
        [:communication_inbound].freeze
      end
    end
  end
end
