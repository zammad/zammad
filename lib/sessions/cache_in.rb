module Sessions::CacheIn

  # rubocop:disable Style/ClassVars
  @@data = {}
  @@data_time = {}
  @@expires_in = {}
  @@expires_in_ttl = {}
  # rubocop:enable Style/ClassVars

  def self.delete(key)
    @@data.delete(key)
    @@data_time.delete(key)
  end

  def self.set(key, value, params = {})
    if params[:expires_in]
      @@expires_in[key]     = Time.zone.now + params[:expires_in]
      @@expires_in_ttl[key] = params[:expires_in]
    end
    @@data[ key ]      = value
    @@data_time[ key ] = Time.zone.now
  end

  def self.expired(key, params = {})

    # expire if value never was set
    return true if !@@data.include? key

    # ignore_expire
    return false if params[:ignore_expire]

    # set re_expire
    if params[:re_expire]
      if @@expires_in[key]
        @@expires_in[key] = Time.zone.now + @@expires_in_ttl[key]
      end
      return false
    end

    # check if expired
    if @@expires_in[key]
      return true if @@expires_in[key] < Time.zone.now
      return false
    end

    # return false if key was set without expires_in
    false
  end

  def self.get(key, params = {})
    return if expired( key, params)
    @@data[ key ]
  end
end
