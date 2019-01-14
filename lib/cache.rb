module Cache

=begin

delete a cache

  Cache.delete('some_key')

=end

  def self.delete(key)
    Rails.cache.delete(key.to_s)
  end

=begin

write a cache

  Cache.write(
    'some_key',
    { some: { data: { 'structure' } } },
    { expires_in: 24.hours, # optional, default 7 days }
  )

=end

  def self.write(key, data, params = {})
    params[:expires_in] ||= 7.days

    # in certain cases, caches are deleted by other thread at same
    # time, just log it
    Rails.cache.write(key.to_s, data, params)
  rescue => e
    Rails.logger.error "Can't write cache #{key}: #{e.inspect}"
    Rails.logger.error e
  end

=begin

get a cache

  value = Cache.get('some_key')

=end

  def self.get(key)
    Rails.cache.read(key.to_s)
  end

=begin

clear whole cache store

  Cache.clear

=end

  def self.clear
    Rails.cache.clear
  end
end
