# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Zammad
  module Deployment
    class << self
      def container?
        # Dockerfile sets this ENV for reliable detection.
        %w[1 true].include?(ENV['ZAMMAD_DOCKER'])
      end
    end
  end
end
