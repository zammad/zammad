# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'icalendar/tzinfo'

class CalendarSubscriptions

  def initialize(user)
    @user        = user
    @preferences = {}
    @time_zone   = Setting.get('timezone_default_sanitized')

    default_preferences = Setting.where(area: 'Defaults::CalendarSubscriptions')
    default_preferences.each do |calendar_subscription|

      next if calendar_subscription.name !~ %r{\Adefaults_calendar_subscriptions_(.*)\z}

      object_name                 = $1 # rubocop:disable Lint/OutOfRangeRegexpRef
      @preferences[ object_name ] = calendar_subscription.state_current[:value]
    end

    return if @user.preferences[:calendar_subscriptions].blank?

    @preferences = @preferences.merge(@user.preferences[:calendar_subscriptions])
  end

  def all
    events_data = []
    @preferences.each_key do |object_name|
      result = generic_call(object_name)
      events_data += result
    end
    to_ical(events_data)
  end

  def generic(object_name, method_name = 'all')
    events_data = generic_call(object_name, method_name)
    to_ical(events_data)
  end

  def generic_call(object_name, method_name = 'all')

    method_name ||= 'all'

    events_data = []
    if @preferences[ object_name ].present?
      sub_class_name = object_name.to_s.capitalize
      object         = "CalendarSubscriptions::#{sub_class_name}".constantize
      instance       = object.new(@user, @preferences[ object_name ], @time_zone)
      method         = instance.method(method_name)
      events_data += method.call
    end
    events_data
  end

  def to_ical(events_data)

    cal = Icalendar::Calendar.new

    tz = ActiveSupport::TimeZone.find_tzinfo(@time_zone)

    # https://github.com/zammad/zammad/issues/3989
    # https://datatracker.ietf.org/doc/html/rfc5545#section-3.2.19
    if events_data.first.present?
      timezone = tz.ical_timezone(DateTime.parse(events_data.first[:dtstart].to_s))
      cal.add_timezone(timezone)
    end

    events_data.each do |event_data|

      cal.event do |e|
        dtstart = DateTime.parse(event_data[:dtstart].to_s)
        dtend   = DateTime.parse(event_data[:dtend].to_s)

        # by design all new/open ticket events are scheduled at midnight:
        # skip adding TZ offset
        if !event_data[:type].match('new_open')
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
