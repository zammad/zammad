module Cache
  def self.delete( key )
    puts 'Cache.delete' + key.to_s
    Rails.cache.delete( key.to_s )
  end
  def self.write( key, data, params = {} )
    if !params[:expires_in]
      params[:expires_in] = 24.hours
    end
    puts 'Cache.write: ' + key.to_s
    Rails.cache.write( key.to_s, data, params)
  end
  def self.get( key )
    puts 'Cache.get: ' + key.to_s
    Rails.cache.read( key.to_s )
  end
  def self.clear
    puts 'Cache.clear...'
    Rails.cache.clear
  end
end