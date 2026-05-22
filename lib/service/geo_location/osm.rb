# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::GeoLocation::Osm
  OSM_SEARCH_URL = 'https://nominatim.openstreetmap.org/search?q=%s&format=jsonv2'.freeze
  OSM_REVERSE_URL = 'https://nominatim.openstreetmap.org/reverse?lat=%s&lon=%s&format=jsonv2'.freeze

  def self.geocode(address)
    url = format(OSM_SEARCH_URL, CGI.escape(address))
    response = UserAgent.get(
      url,
      {},
      {
        verify_ssl: true,
      },
    )
    return if !response.success?

    result = JSON.parse(response.body)

    return if !result || !result.first

    lat = result.first['lat'].to_f
    lng = result.first['lon'].to_f

    [lat, lng]
  end

  def self.reverse_geocode(lat, lng)
    url = format(OSM_REVERSE_URL, lat, lng)
    response = UserAgent.get(
      url,
      {},
      {
        json:       true,
        verify_ssl: true,
      },
    )
    return if !response.success?

    result = JSON.parse(response.body)

    return if !result

    result['display_name']
  end
end
