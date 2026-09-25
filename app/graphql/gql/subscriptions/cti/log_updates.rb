# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Cti::LogUpdates < BaseSubscription
    description 'Changes to the caller log of the CTI integration'

    subscription_scope :current_user_id

    requires_permission 'cti.agent'

    field :add_log, Gql::Types::Cti::LogType, description: 'A new call needs to be added to the caller log'
    field :update_log, Gql::Types::Cti::LogType, description: 'An existing call was changed'
    field :remove_log_id, GraphQL::Types::ID, description: 'A call must be removed from the caller log'

    class << self
      # Helper methods for triggering with custom payload, one call per receiving agent.
      def trigger_after_create(log, user)
        trigger_for_user({ add_log: log }, user)
      end

      def trigger_after_update(log, user)
        trigger_for_user({ update_log: log }, user)
      end

      def trigger_after_destroy(log, user)
        trigger_for_user({ remove_log_id: Gql::ZammadSchema.id_from_object(log) }, user)
      end

      def trigger_for_user(payload, user)
        trigger(payload, scope: user.id)
      end
    end

    def update
      object
    end
  end
end
