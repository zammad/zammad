# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Service
  class GeoLocation
    include ApplicationLib

=begin

lookup lat and lng for address

  result = Service::GeoLocation.geocode('Marienstrasse 13, 10117 Berlin')

returns

  result = [ 4.21312, 1.3123 ]

=end

    def self.geocode(address)

      # load backend
      backend = load_adapter_by_setting('geo_location_backend')
      return if !backend

      # db lookup
      backend.geocode(address)
    end

=begin

lookup address for lat and lng

  result = GeoLocation.reverse_geocode(4.21312, 1.3123)

returns

  result = 'some address'

=end

    def self.reverse_geocode(lat, lng)

      # load backend
      backend = load_adapter_by_setting('geo_location_backend')
      return if !backend

      # db lookup
      backend.reverse_geocode(lat, lng)
    end
  end
end
