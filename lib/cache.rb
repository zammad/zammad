module Cache
  def self.delete( key )
    puts 'Cache.delete' + key.to_s
    Rails.cache.delete( key.to_s )
  end
  def self.write( key, data )
    puts 'Cache.write: ' + key.to_s
    Rails.cache.write( key.to_s, data )
  end
  def self.get( key )
    puts 'Cache.get: ' + key.to_s
    Rails.cache.read( key.to_s )
  end
end