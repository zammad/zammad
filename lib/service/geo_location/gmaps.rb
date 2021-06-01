# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Service::GeoLocation::Gmaps

  def self.geocode(address)
    url = "http://maps.googleapis.com/maps/api/geocode/json?address=#{CGI.escape address}&sensor=true"
    response = UserAgent.get(
      url,
      {},
      {
        open_timeout:  2,
        read_timeout:  4,
        total_timeout: 4,
      },
    )
    return if !response.success?

    result = JSON.parse(response.body)

    return if !result
    return if !result['results']
    return if !result['results'].first

    lat = result['results'].first['geometry']['location']['lat']
    lng = result['results'].first['geometry']['location']['lng']
    [lat, lng]
  end

  def self.reverse_geocode(lat, lng)
    url = "http://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{lng}&sensor=true"
    response = UserAgent.get(
      url,
      {},
      {
        json:          true,
        open_timeout:  2,
        read_timeout:  4,
        total_timeout: 4,
      },
    )
    return if !response.success?

    result = JSON.parse(response.body)

    result['results'].first['address_components'].first['long_name']

  end
end
