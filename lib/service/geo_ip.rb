# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Service
  class GeoIp
    include ApplicationLib

=begin

lookup location based on ip or hostname

  result = Service::GeoIp.location('172.0.0.1')

returns

  result = {
    "ip"            => "172.0.0.1"
    "country_code"  => "DE",
    "country_name"  => "Germany",
    "region_code"   => "05",
    "region_name"   => "Hessen",
    "city"          => "Frankfurt Am Main"
    "zipcode"       => "12345",
    "latitude"      => 50.1167,
    "longitude"     => 8.6833,
    "metro_code"    => "",
    "areacode"      => ""
  }

=end

    def self.location(address)

      # load backend
      backend = load_adapter_by_setting('geo_ip_backend')
      return if !backend

      # db lookup
      backend.location(address)
    end
  end
end
