module Sessions::Backend::ActivityStream
  @@last_change = {}

  def self.worker( user, worker )
    cache_key = 'user_' + user.id.to_s + '_activity_stream'
    if Sessions::CacheIn.expired(cache_key)
      activity_stream = History.activity_stream( user, 20 )
      activity_stream_cache = Sessions::CacheIn.get( cache_key, { :re_expire => true } )
      worker.log 'notice', 'fetch activity_stream - ' + cache_key
      if activity_stream != activity_stream_cache
        worker.log 'notify', 'fetch activity_stream changed - ' + cache_key

        activity_stream_full = History.activity_stream_fulldata( user, 20 )
        Sessions::CacheIn.set( cache_key, activity_stream, { :expires_in => 0.75.minutes } )
        Sessions::CacheIn.set( cache_key + '_push', activity_stream_full )
      end
    end
  end

  def self.push( user, client )
    cache_key = 'user_' + user.id.to_s + '_activity_stream'

    activity_stream_time = Sessions::CacheIn.get_time( cache_key, { :ignore_expire => true } )
    if activity_stream_time && @@last_change[ user.id ] != activity_stream_time
      @@last_change[ user.id ] = activity_stream_time
      activity_stream = Sessions::CacheIn.get( cache_key, { :ignore_expire => true } )
      client.log 'notify', "push activity_stream for user #{user.id}"

      # send update to browser
      r = Sessions::CacheIn.get( cache_key + '_push', { :ignore_expire => true } )
      client.send({
        :event      => 'activity_stream_rebuild',
        :collection => 'activity_stream', 
        :data       => r,
      })
    end
  end

end