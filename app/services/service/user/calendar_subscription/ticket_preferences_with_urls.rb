# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::User::CalendarSubscription::TicketPreferencesWithUrls < Service::Base
  attr_reader :user

  def initialize(user)
    super()

    @user = user
  end

  def execute
    output = {
      combined_url:   generate_url,
      global_options: { alarm: preferences[:alarm] }
    }

    %i[new_open pending escalation].each_with_object(output) do |elem, memo|
      memo[elem] = { options: preferences[elem], url: generate_url(elem) }
    end
  end

  private

  def preferences
    @preferences ||= Service::User::CalendarSubscription::Preferences
      .new(user)
      .execute
      .fetch(:tickets)
  end

  def generate_url(suffix = nil)
    http_type = Setting.get('http_type')
    fqdn      = Setting.get('fqdn')

    ["#{http_type}://#{fqdn}/ical/tickets", suffix]
      .compact
      .join('/')
  end
end
