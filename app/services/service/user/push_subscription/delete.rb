# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::PushSubscription::Delete < Service::Base
  requires_current_user!

  attr_reader :endpoint

  def initialize(endpoint:)
    @endpoint = endpoint
  end

  def execute
    current_user.push_subscriptions.find_by(endpoint:)&.destroy!

    true
  end
end
