# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module ICal

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
