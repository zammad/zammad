# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module ICal

  def self.preferenced(user)

    events_data = []

    user.preferences[:ical].each { |sub_class, _sub_structure|

      sub_class_name = sub_class.to_s.capitalize
      class_name     = "ICal::#{sub_class_name}"

      object       = Kernel.const_get( class_name )
      events_data += object.preferenced( user )
    }

    to_ical( events_data )
  end

  def self.to_ical(events_data)

    cal = Icalendar::Calendar.new

    events_data.each do |event_data|

      cal.event do |e|
        e.dtstart     = event_data[:dtstart]
        e.dtend       = event_data[:dtend]
        e.summary     = event_data[:summary]
        e.description = event_data[:description]
        e.ip_class    = 'PRIVATE'
      end

    end

    cal.to_ical
  end

end
