require 'simple-rss'
module Rss
  def self.fetch(url, limit = 10)
    cache_key = 'rss::' + url
    items = Cache.get( cache_key )
    return items if items

    begin
      puts 'fetch rss...'
      response = UserAgent.request(url)
      if !response.success?
        raise "Can't fetch '#{url}', http code: #{response.code.to_s}"
        return
      end
      rss     = SimpleRSS.parse response.body
      items   = []
      fetched = 0
      rss.items.each { |item|
        record = {
          :id        => item.id,
          :title     => Encode.conv( 'utf8', item.title ),
          :summary   => Encode.conv( 'utf8', item.summary ),
          :link      => item.link,
          :published => item.published
        }
        items.push record
        fetched += 1
        break item if fetched == limit.to_i
      }
      Cache.write( cache_key, items, :expires_in => 4.hours )
    rescue Exception => e
      puts "can't fetch #{url}"
      puts e.inspect
      return
    end

    return items
  end
end
