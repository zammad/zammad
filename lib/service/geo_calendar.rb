# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Service
  class GeoCalendar
    include ApplicationLib

=begin

lookup calendar based on ip or hostname

  result = Service::GeoCalendar.location( '99.99.99.99' )

lookup calendar based on own system ip

  result = Service::GeoCalendar.location

returns

  result = {
    "name" => 'Country Name',
    "timezone" => 'time zone of ip',
    "business_hours" => {
      "mon" => {
        "active" => true,
        "timeframes" => [["09:00","17:00"]]
      },
      "tue" => {
        "active" => true,
        "timeframes" => [["09:00","17:00"]]
      },
      "wed":{
        "active" => true,
        "timeframes" => [["09:00","17:00"]]
      },
      "thu":{
        "active" => true,
        "timeframes" => [["09:00","17:00"]]
      },
      "fri":{
        "active" => true,
        "timeframes" => [["09:00","17:00"]]
      },
      "sat":{
        "active" => false,
        "timeframes" => [["09:00","17:00"]]
      },
      "sun":{
        "active" => false,
        "timeframes" => [["09:00","17:00"]]
      }
    },
    "ical_url" => "",
  }

=end

    def self.location(address = nil)

      # load backend
      backend = load_adapter_by_setting('geo_calendar_backend')
      return if !backend

      # db lookup
      backend.location(address)
    end
  end
end
