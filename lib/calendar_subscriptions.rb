# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class CalendarSubscriptions

  def initialize(user)
    @user        = user
    @preferences = {}

    default_preferences = Setting.where(area: 'Defaults::CalendarSubscriptions')
    default_preferences.each { |calendar_subscription|

      next if calendar_subscription.name !~ /\Adefaults_calendar_subscriptions_(.*)\z/

      object_name                 = $1
      @preferences[ object_name ] = calendar_subscription.state_current[:value]
    }

    return if !@user.preferences[:calendar_subscriptions]
    return if @user.preferences[:calendar_subscriptions].empty?
    @preferences = @preferences.merge(@user.preferences[:calendar_subscriptions])
  end

  def all
    events_data = []
    @preferences.each { |object_name, _sub_structure|
      result      = generic_call(object_name)
      events_data = events_data + result
    }
    to_ical(events_data)
  end

  def generic(object_name, method_name = 'all')
    events_data = generic_call(object_name, method_name)
    to_ical(events_data)
  end

  def generic_call(object_name, method_name = 'all')

    method_name ||= 'all'

    events_data = []
    if @preferences[ object_name ] && !@preferences[ object_name ].empty?
      sub_class_name = object_name.to_s.capitalize
      object         = Object.const_get("CalendarSubscriptions::#{sub_class_name}")
      instance       = object.new(@user, @preferences[ object_name ])
      method         = instance.method(method_name)
      events_data += method.call
    end
    events_data
  end

  def to_ical(events_data)

    cal = Icalendar::Calendar.new

    events_data.each do |event_data|

      cal.event do |e|
        e.dtstart     = event_data[:dtstart]
        e.dtend       = event_data[:dtend]
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
