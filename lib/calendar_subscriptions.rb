# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'icalendar/tzinfo'

class CalendarSubscriptions

  def initialize(user)
    @user        = user
    @time_zone   = Setting.get('timezone_default')
    @preferences = Service::User::CalendarSubscription::Preferences.new(@user).execute
  end

  def all
    to_ical @preferences
      .keys
      .map { |object_name| generic_call(object_name) }
      .flatten
  end

  def generic(object_name, method_name = 'all')
    to_ical generic_call(object_name, method_name)
  end

  def generic_call(object_name, method_name = 'all')
    return [] if @preferences[ object_name ].blank?

    sub_class_name = object_name.to_s.capitalize
    object         = "CalendarSubscriptions::#{sub_class_name}".constantize
    instance       = object.new(@user, @preferences[ object_name ], @time_zone)

    raise Exceptions::UnprocessableEntity, __('An unknown method name was requested.') if object::ALLOWED_METHODS.exclude?(method_name)

    instance.send(method_name)
  end

  def to_ical(events_data)
    cal = Icalendar::Calendar.new
    tz  = ActiveSupport::TimeZone.find_tzinfo(@time_zone)

    # https://github.com/zammad/zammad/issues/3989
    # https://datatracker.ietf.org/doc/html/rfc5545#section-3.2.19
    if events_data.any?
      cal.add_timezone tz.ical_timezone(DateTime.parse(events_data.first[:dtstart].to_s))
    end

    events_data.each do |event_data|

      cal.event do |e|
        dtstart = DateTime.parse(event_data[:dtstart].to_s)
        dtend   = DateTime.parse(event_data[:dtend].to_s)

        # by design all new/open ticket events are scheduled at midnight:
        # skip adding TZ offset
        if event_data[:type] != 'new_open'
          dtstart = tz.utc_to_local(dtstart)
          dtend = tz.utc_to_local(dtend)
        end

        e.dtstart = Icalendar::Values::DateTime.new(dtstart, 'tzid' => @time_zone)
        e.dtend   = Icalendar::Values::DateTime.new(dtend, 'tzid' => @time_zone)
        if event_data[:alarm]
          e.alarm do |a|
            a.action  = 'DISPLAY'
            a.summary = event_data[:alarm][:summary]
            a.trigger = event_data[:alarm][:trigger]
          end
        end
        e.summary     = event_data[:summary]
        e.description = event_data[:description]
        e.ip_class    = 'PRIVATE'
      end

    end

    cal.to_ical
  end

end
