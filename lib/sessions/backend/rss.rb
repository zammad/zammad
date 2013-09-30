module Sessions::Backend::Rss

  def self.worker( user, worker )
    cache_key = 'user_' + user.id.to_s + '_rss'
    if Sessions::CacheIn.expired(cache_key)
      url = 'http://www.heise.de/newsticker/heise-atom.xml'
      rss_items = Rss.fetch( url, 8 )
      rss_items_cache = Sessions::CacheIn.get( cache_key, { :re_expire => true } )
      worker.log 'notice', 'fetch rss - ' + cache_key
      if rss_items != rss_items_cache
        worker.log 'notify', 'fetch rss changed - ' + cache_key
        Sessions::CacheIn.set( cache_key, rss_items, { :expires_in => 2.minutes } )
        Sessions::CacheIn.set( cache_key + '_push', {
          head:  'Heise ATOM',
          items: rss_items,
        })
      end
    end
  end

  def self.push( user, client )
    cache_key = 'user_' + user.id.to_s + '_rss'

    rss_items_time = Sessions::CacheIn.get_time( cache_key, { :ignore_expire => true } )
    if rss_items_time && client.last_change['rss'] != rss_items_time
      client.last_change['rss'] = rss_items_time
      rss_items = Sessions::CacheIn.get( cache_key, { :ignore_expire => true } )
      client.log 'notify', "push rss for user #{user.id}"

      # send update to browser
      r = Sessions::CacheIn.get( cache_key + '_push', { :ignore_expire => true } )
      client.send({
        :event      => 'rss_rebuild',
        :collection => 'dashboard_rss',
        :data       => r,
      })
    end
  end

end 
