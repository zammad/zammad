module Sessions::Backend::TicketOverviewIndex

  def self.worker( user, worker )
    cache_key = 'user_' + user.id.to_s + '_overview'
    if Sessions::CacheIn.expired(cache_key)
      overview = Ticket::Overviews.list(
        :current_user => user,
      )
      overview_cache = Sessions::CacheIn.get( cache_key, { :re_expire => true } )
      worker.log 'notice', 'fetch overview - ' + cache_key
      if overview != overview_cache
        worker.log 'notify', 'fetch overview changed - ' + cache_key
#          puts overview.inspect
#          puts '------'
#          puts overview_cache.inspect
        Sessions::CacheIn.set( cache_key, overview, { :expires_in => 4.seconds } )
      end
    end
  end

  def self.push( user, client )
    cache_key = 'user_' + user.id.to_s + '_overview'
    overview_time = Sessions::CacheIn.get_time( cache_key, { :ignore_expire => true } )
    if overview_time && client.last_change['overview'] != overview_time
      client.last_change['overview'] = overview_time
      overview = Sessions::CacheIn.get( cache_key, { :ignore_expire => true } )

      client.log 'notify', "push overview for user #{user.id}"

      # send update to browser
      client.send({
        :event  => 'navupdate_ticket_overview',
        :data   => overview,
      })
    end
  end

end