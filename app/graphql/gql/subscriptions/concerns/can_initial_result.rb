# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions::Concerns::CanInitialResult
  extend ActiveSupport::Concern

  class_methods do
    def unique_argument_id_key(key)
      @unique_argument_id_key ||= key
    end

    # This is needed to ensure that the subscription is unique for each user and that `initial` is not considered.
    def topic_for(arguments:, field:, scope:)
      super(arguments: { @unique_argument_id_key => arguments[@unique_argument_id_key] }, field:, scope:)
    end
  end

  included do
    argument :initial, GraphQL::Types::Boolean, default_value: false, description: 'Return initial data by subscribing'
  end
end
