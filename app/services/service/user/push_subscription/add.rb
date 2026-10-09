# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::PushSubscription::Add < Service::Base
  requires_current_user!

  attr_reader :endpoint, :keys

  def initialize(endpoint:, keys:)
    @endpoint = endpoint
    @keys     = keys
  end

  # A push endpoint identifies one browser on one device. When another
  #   account logs in there, the subscription has to follow that account,
  #   otherwise the device keeps receiving the previous user's notifications.
  def execute
    subscription = ::PushSubscription.find_or_initialize_by(endpoint:)

    subscription.assign_attributes(
      user:   current_user,
      p256dh: keys[:p256dh],
      auth:   keys[:auth],
    )

    subscription.save!

    subscription
  end
end
