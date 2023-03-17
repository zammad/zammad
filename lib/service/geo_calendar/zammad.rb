# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::GeoCalendar::Zammad
  def self.location(address)

    # check cache
    cache_key = "zammadgeocalendar::#{address}"
    cache = ::Rails.cache.read(cache_key)
    return cache if cache

    # do lookup
    host = 'https://geo.zammad.com'
    url = if address
            "/calendar?ip=#{CGI.escape address}"
          else
            '/calendar'
          end
    data = {}
    begin
      response = UserAgent.get(
        "#{host}#{url}",
        {},
        {
          json:          true,
          open_timeout:  2,
          read_timeout:  4,
          total_timeout: 12,
          verify_ssl:    true,
        },
      )
      if !response.success? && response.code.to_s !~ %r{^40.$}
        raise "#{response.code}/#{response.body}"
      end

      data = response.data

      ::Rails.cache.write(cache_key, data, { expires_in: 30.minutes })
    rescue => e
      Rails.logger.error "#{host}#{url}: #{e.inspect}"
      ::Rails.cache.write(cache_key, data, { expires_in: 1.minute })
    end
    data
  end
end
