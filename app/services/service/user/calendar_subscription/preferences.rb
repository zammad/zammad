# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::User::CalendarSubscription::Preferences < Service::Base
  attr_reader :user

  def initialize(user)
    super()

    @user = user
  end

  def execute
    default_preferences
      .merge(user_preferences)
      .tap { |elem| elem[:tickets][:alarm] = !!elem.dig(:tickets, :alarm) } # ensure alarm is set to false if it's not set
  end

  private

  def default_settings
    Setting
      .where(area: 'Defaults::CalendarSubscriptions')
      .where("name LIKE 'defaults_calendar_subscriptions_%'")
  end

  def default_preferences
    default_settings
      .to_h do |elem|
        [
          elem.name.delete_prefix('defaults_calendar_subscriptions_'),
          elem.state_current[:value]
        ]
      end
      .with_indifferent_access
  end

  def user_preferences
    user.preferences[:calendar_subscriptions] || {}
  end
end
