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
    if !params[:expires_in]
      params[:expires_in] = 7.days
    end

    # in certain cases, caches are deleted by other thread at same
    # time, just log it
    begin
      Rails.cache.write(key.to_s, data, params)
    rescue => e
      Rails.logger.error "Can't write cache #{key}: #{e.inspect}"
    end
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
    # workaround, set test cache before clear whole cache, Rails.cache.clear complains about not existing cache dir
    Cache.write('test', 1)

    Rails.cache.clear
  end
end
