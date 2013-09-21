module Sessions::Backend::RecentViewed
  @@last_change = {}

  def self.worker( user, worker )
    cache_key = 'user_' + user.id.to_s + '_recent_viewed'
    if Sessions::CacheIn.expired(cache_key)
      recent_viewed = RecentView.list_fulldata( user, 10 )
      recent_viewed_cache = Sessions::CacheIn.get( cache_key, { :re_expire => true } )
      worker.log 'notice', 'fetch recent_viewed - ' + cache_key
      if recent_viewed != recent_viewed_cache
        worker.log 'notify', 'fetch recent_viewed changed - ' + cache_key

        recent_viewed_full = RecentView.list_fulldata( user, 10 )
        Sessions::CacheIn.set( cache_key, recent_viewed, { :expires_in => 5.seconds } )
        Sessions::CacheIn.set( cache_key + '_push', recent_viewed_full )
      end
    end

  end

  def self.push( user, client )
    cache_key = 'user_' + user.id.to_s + '_recent_viewed'
    recent_viewed_time = Sessions::CacheIn.get_time( cache_key, { :ignore_expire => true } )
    if recent_viewed_time && @@last_change[ user.id ] != recent_viewed_time
      @@last_change[ user.id ] = recent_viewed_time
      recent_viewed = Sessions::CacheIn.get( cache_key, { :ignore_expire => true } )
      client.log 'notify', "push recent_viewed for user #{user.id}"

      # send update to browser
      r = Sessions::CacheIn.get( cache_key + '_push', { :ignore_expire => true } )
      client.send({
        :event      => 'update_recent_viewed',
        :data       => r,
      })
    end
  end

end 
