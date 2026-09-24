# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The browser tab a GraphQL operation came from, together with the subscriptions it does not need
#   to receive for the changes it makes itself (e.g. because its result already holds them).
#   Everything committed while the operation runs counts as its own - including what the transaction
#   backends of a nested Transaction.execute change, like ticket triggers.
class Gql::SubscriptionOrigin
  attr_reader :browser_tab_id, :skip_subscriptions

  def self.current
    Thread.current[:gql_subscription_origin]
  end

  def self.with(browser_tab_id:, skip_subscriptions:)
    previous = current

    Thread.current[:gql_subscription_origin] = if browser_tab_id.present? && skip_subscriptions.present?
                                                 new(browser_tab_id:, skip_subscriptions:)
                                               end

    yield
  ensure
    Thread.current[:gql_subscription_origin] = previous
  end

  # The browser tab which must not receive the updates of the given subscription triggered right now.
  def self.skipped_browser_tab_id(graphql_field_name)
    origin = current
    return if !origin&.skip_subscriptions&.include?(graphql_field_name.to_s)

    origin.browser_tab_id
  end

  def initialize(browser_tab_id:, skip_subscriptions:)
    @browser_tab_id     = browser_tab_id.to_s
    @skip_subscriptions = Array(skip_subscriptions).map(&:to_s)
  end
end
