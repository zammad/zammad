# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Leaves out the browser tab which caused an update and said it does not need it, see Gql::SubscriptionOrigin.
#   The stock implementation broadcasts the bare object only, so the tab to skip is wrapped around it.
class Gql::ActionCableSubscriptions < GraphQL::Subscriptions::ActionCableSubscriptions
  def execute_all(event, object)
    skipped_browser_tab_id = event.context[:skipped_browser_tab_id]
    return super if skipped_browser_tab_id.blank?

    @action_cable.server.broadcast(
      stream_event_name(event),
      { 'skipped_browser_tab_id' => skipped_browser_tab_id, 'object' => @serializer.dump(object) },
    )
  end

  # Loading, executing and delivering a broadcast run in one go on the same thread and every delivery
  #   follows its load, so the value set here is always the one of the broadcast being delivered.
  def load_action_cable_message(message, context)
    wrapped = message.is_a?(Hash)

    Thread.current[:gql_skipped_browser_tab_id] = wrapped ? message['skipped_browser_tab_id'] : nil

    super(wrapped ? message['object'] : message, context)
  end

  def deliver(subscription_id, result)
    return if skipped_browser_tab?(subscription_id)

    super
  end

  private

  def skipped_browser_tab?(subscription_id)
    skipped_browser_tab_id = Thread.current[:gql_skipped_browser_tab_id]
    return false if skipped_browser_tab_id.blank?

    @subscriptions[subscription_id]&.context&.[](:browser_tab_id) == skipped_browser_tab_id
  end
end
