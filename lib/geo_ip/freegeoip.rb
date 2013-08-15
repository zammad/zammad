require 'faraday'
require 'cache'

class GeoIp::Freegeoip
  def self.location(address)

    # check cache
    cache_key = "freegeoip::#{address}"
    cache = Cache.get( cache_key )
    return cache if cache

    # do lookup
    host = "http://freegeoip.net"
    url  = "/json/#{CGI::escape address}"
    data = {}
    begin
      conn = Faraday.new( :url => host )
      response = conn.get url
      data = JSON.parse( response.body )
      Cache.write( cache_key, data, { :expires_in => 90.days } )
    rescue
      Cache.write( cache_key, data, { :expires_in => 60.minutes } )
    end
    data
  end
end
