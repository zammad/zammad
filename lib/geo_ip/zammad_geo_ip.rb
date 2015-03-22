# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

require 'cache'

class GeoIp::ZammadGeoIp
  def self.location(address)

    # check cache
    cache_key = "zammadgeoip::#{address}"
    cache = Cache.get( cache_key )
    return cache if cache

    # do lookup
    host = "https://geo.zammad.com"
    url  = "/lookup?ip=#{CGI::escape address}"
    data = {}
    begin
      response = UserAgent.get(
        "#{host}#{url}",
        {
          :open_timeout => 2,
          :read_timeout => 4,
        },
      )
      if !response.success? && response.code.to_s !~ /^40.$/
        raise "ERROR: #{response.code.to_s}/#{response.body}"
      end

      data = JSON.parse( response.body )

      # compat. map
      if data && data['country_code2']
        data['country_code'] = data['country_code2']
      end

      Cache.write( cache_key, data, { :expires_in => 90.days } )
    rescue => e
      puts "ERROR: #{host}#{url}: " + e.inspect
      Cache.write( cache_key, data, { :expires_in => 60.minutes } )
    end
    data
  end
end