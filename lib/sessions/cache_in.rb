module Sessions::CacheIn
  @@data = {}
  @@data_time = {}
  @@expires_in = {}
  @@expires_in_ttl = {}

  def self.delete( key )
    @@data.delete( key )
    @@data_time.delete( key )
  end

  def self.set( key, value, params = {} )
#    puts 'CacheIn.set:' + key + '-' + value.inspect
    if params[:expires_in]
      @@expires_in[key] = Time.now + params[:expires_in]
      @@expires_in_ttl[key] = params[:expires_in]
    end
    @@data[ key ] = value
    @@data_time[ key ] = Time.now
  end

  def self.expired( key, params = {} )

    # expire if value never was set
    return true if !@@data.include? key

    # ignore_expire
    return false if params[:ignore_expire]

    # set re_expire
    if params[:re_expire]
      if @@expires_in[key]
        @@expires_in[key] = Time.now + @@expires_in_ttl[key]
      end
      return false
    end

    # check if expired
    if @@expires_in[key]
      return true if @@expires_in[key] < Time.now
      return false
    end

    # return false if key was set without expires_in
    false
  end

  def self.get_time( key, params = {} )
    data = self.get( key, params )
    if data
      return @@data_time[key]
    end
    nil
  end

  def self.get( key, params = {} )
#    puts 'CacheIn.get:' + key + '-' + @@data[ key ].inspect
    return if self.expired( key, params )
    @@data[ key ]
  end
end
