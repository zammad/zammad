module Sessions::Backend::TicketCreate

  def self.worker( user, worker )
    cache_key = 'user_' + user.id.to_s + '_ticket_create_attributes'

    if Sessions::CacheIn.expired(cache_key)
      ticket_create_attributes = Ticket::ScreenOptions.attributes_to_change(
        :current_user_id => user.id,
      )
      ticket_create_attributes_cache = Sessions::CacheIn.get( cache_key, { :re_expire => true } )
      worker.log 'notice', 'fetch ticket_create_attributes - ' + cache_key
      if ticket_create_attributes != ticket_create_attributes_cache
        worker.log 'notify', 'fetch ticket_create_attributes changed - ' + cache_key
        Sessions::CacheIn.set( cache_key, ticket_create_attributes, { :expires_in => 2.minutes } )
      end
    end

  end

  def self.push( user, client )
    cache_key = 'user_' + user.id.to_s + '_ticket_create_attributes'

    ticket_create_attributes_time = Sessions::CacheIn.get_time( cache_key, { :ignore_expire => true } )
    if ticket_create_attributes_time && client.last_change['ticket_create_attributes'] != ticket_create_attributes_time
      client.last_change['ticket_create_attributes'] = ticket_create_attributes_time
      create_attributes = Sessions::CacheIn.get( cache_key, { :ignore_expire => true } )
      users = {}
      create_attributes[:owner_id].each {|user_id|
        if !users[user_id]
          users[user_id] = User.user_data_full(user_id)
        end
      }
      data = {
        :users     => users,
        :edit_form => create_attributes,
      }
      client.log 'notify', "push ticket_create_attributes for user #{user.id}"

      # send update to browser
      client.send({
        :collection => 'ticket_create_attributes',
        :data       => data,
      })
    end
  end

end 
