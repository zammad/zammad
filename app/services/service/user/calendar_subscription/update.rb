# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::CalendarSubscription::Update < Service::Base
  attr_reader :user, :input

  def initialize(user, input:)
    super()

    @user  = user
    @input = input
  end

  def execute
    user.preferences[:calendar_subscriptions] ||= {}
    user.preferences[:calendar_subscriptions][:tickets] = build_subscription_preferences(input)

    user.save!
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
