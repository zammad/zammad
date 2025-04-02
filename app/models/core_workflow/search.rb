# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow
  module Search
    extend ActiveSupport::Concern

    include CanSearch

    included do
      scope :search_sql_extension, lambda { |_params|
        all.changeable
      }
    end

    class_methods do
      def search_query_extension(_params)
        {
          bool: {
            must: [
              {
                term: { 'changeable' => true }
              },
            ],
          }
        }
      end
    end
  end
end
