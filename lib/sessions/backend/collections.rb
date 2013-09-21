module Sessions::Backend::Collections
  @@last_change = {}

  def self.worker( user, worker )

    worker.log 'notice', "---user - fetch push_collection data"

    # get available collections
    cache_key = 'user_' + user.id.to_s + '_push_collections'
    collections = Sessions::CacheIn.get( cache_key )
    if !collections
      collections = {}
      push_collection = SessionHelper::push_collections(user)
      push_collection.each { | key, value |
        collections[ key ] = true
      }
      Sessions::CacheIn.set( cache_key, collections, { :expires_in => 2.minutes } )
    end

    # check all collections to push
    push_collection = {}
    collections.each { | key, v |
      cache_key = 'user_' + user.id.to_s + '_push_collections_' + key
      if Sessions::CacheIn.expired(cache_key)
        if push_collection.empty?
          push_collection = SessionHelper::push_collections(user)
        end
        push_collection_cache = Sessions::CacheIn.get( cache_key, { :re_expire => true } )
        worker.log 'notice', "---user - fetch push_collection data " + cache_key
        if !push_collection[key] || !push_collection_cache || push_collection[key] != push_collection_cache || !push_collection[ key ].zip( push_collection_cache ).all? { |x, y| x.attributes == y.attributes }
          worker.log 'notify', 'fetch push_collection changed - ' + cache_key
          Sessions::CacheIn.set( cache_key, push_collection[key], { :expires_in => 1.minutes } )
        end
      end
    }

  end

  def self.push( user, client )

    cache_key = 'user_' + user.id.to_s + '_push_collections'
    if !@@last_change[ user.id ]
      @@last_change[ user.id ] = {}
    end

    collections = Sessions::CacheIn.get( cache_key ) || {}
    collections.each { | key, v |
      collection_cache_key = 'user_' + user.id.to_s + '_push_collections_' + key
      collection_time = Sessions::CacheIn.get_time( collection_cache_key, { :ignore_expire => true } )
      if collection_time && @@last_change[ user.id ][ key ] != collection_time

        @@last_change[ user.id ][ key ] = collection_time
        push_collections = Sessions::CacheIn.get( collection_cache_key, { :ignore_expire => true } )

        client.log 'notify', "push push_collections #{key} for user #{user.id}"

        # send update to browser
        data = {}
        data['collections'] = {}
        data['collections'][key] = push_collections
        client.send({
          :event  => 'resetCollection',
          :data   => data,
        })

      end
    }
  end

end 
