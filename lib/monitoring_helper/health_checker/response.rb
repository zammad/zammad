# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class Response
      attr_reader :issues, :actions

      def initialize
        @issues  = []
        @actions = Set.new
      end

      def merge(another_response)
        @issues.concat another_response.issues
        @actions.merge another_response.actions
      end
    end
  end
end
