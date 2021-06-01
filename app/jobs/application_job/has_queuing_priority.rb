# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ApplicationJob
  module HasQueuingPriority
    extend ActiveSupport::Concern

    included do
      queue_with_priority 200
    end

    class_methods do
      def low_priority
        queue_with_priority 300
      end
    end
  end
end
