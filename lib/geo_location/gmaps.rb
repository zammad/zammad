# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class GeoLocation::Gmaps

  def self.geocode(address)
    url = "http://maps.googleapis.com/maps/api/geocode/json?address=#{CGI::escape address}&sensor=true"
    response = UserAgent.request(url)
    return if !response.success?

    result = JSON.parse( response.body )

    lat = result['results'].first['geometry']['location']['lat']
    lng = result['results'].first['geometry']['location']['lng']
    latlng = [lat,lng]
  end

  def self.reverse_geocode(lat,lng)
    url = "http://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{lng}&sensor=true"
    response = UserAgent.request(url)
    return if !response.success?

    result = JSON.parse( response.body )

    address = result['results'].first['address_components'].first['long_name']
    return address
  end
end
