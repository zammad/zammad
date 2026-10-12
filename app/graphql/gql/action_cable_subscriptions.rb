# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Gql::ActionCableSubscriptions < GraphQL::Subscriptions::ActionCableSubscriptions

  # A broadcastable update is computed once and then delivered to every subscriber sharing it, so
  #   leaving a subscriber out is decided per delivery. Public subscriptions still reach a connection
  #   that is no longer authorized, computed for a logged out client (see
  #   Gql::Context::CurrentUserAware) - the config updates the front end logs out on, for instance.
  def deliver(subscription_id, result)
    return if !subscriber_authorized?(subscription_id)

    super
  end

  private

  def subscriber_authorized?(subscription_id)
    query = @subscriptions[subscription_id]
    return true if !query

    connection = query.context[:channel]&.connection
    return true if !connection || connection.still_authorized?

    !subscription_requires_authentication?(query)
  end

  def subscription_requires_authentication?(query)
    field_name = query.selected_operation.selections.first.name
    resolver   = @schema.get_field(@schema.subscription, field_name)&.resolver

    resolver.nil? || resolver.require_authentication != false
  end
end
