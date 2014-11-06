module Cache
  def self.delete( key )
#    puts 'Cache.delete' + key.to_s
    Rails.cache.delete( key.to_s )
  end
  def self.write( key, data, params = {} )
    if !params[:expires_in]
      params[:expires_in] = 24.hours
    end
#    puts 'Cache.write: ' + key.to_s
    begin
      Rails.cache.write( key.to_s, data, params)
    rescue Exception => e
      puts "NOTICE: #{e.message}"
    end
  end
  def self.get( key )
#    puts 'Cache.get: ' + key.to_s
    Rails.cache.read( key.to_s )
  end
  def self.clear
#    puts 'Cache.clear...'
    # workaround, set test cache before clear whole cache, Rails.cache.clear complains about not existing cache dir
    Cache.write( 'test', 1 )

    Rails.cache.clear
  end
end