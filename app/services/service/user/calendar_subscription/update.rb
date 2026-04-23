# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::CalendarSubscription::Update < Service::Base
  requires_current_user!
  attr_reader :input

  def initialize(input:)
    @input = input
  end

  def execute
    current_user.preferences[:calendar_subscriptions] ||= {}
    current_user.preferences[:calendar_subscriptions][:tickets] = build_subscription_preferences(input)

    current_user.save!
  end

  private

  def build_subscription_preferences(input)
    output = { alarm: input[:alarm] }

    %i[new_open pending escalation]
      .each_with_object(output) do |elem, memo|
        memo[elem] = input[elem]
      end
  end
end
