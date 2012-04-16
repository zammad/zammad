class ApplicationModel < ActiveRecord::Base
  self.abstract_class = true

  def cache_update(o)
#    puts 'u ' + self.class.to_s
    if self.respond_to?('cache_delete') then self.cache_delete end
#    puts 'g ' + group.class.to_s
    if o.respond_to?('cache_delete') then o.cache_delete end
  end
  def cache_delete
#    puts 'cache_delete', self.inspect
    puts 'cache_delete', self.id
    key = self.class.to_s + '::' + self.id.to_s
    puts key
    Rails.cache.delete( key.to_s )
  end
  def self.cache_set(data_id, data)
#    puts 'cache_set', self.inspect
#    puts 'cache_set', self.to_s
    puts 'cache_set', data_id
    key = self.to_s + '::' + data_id.to_s
    puts key
    Rails.cache.write( key.to_s, data)
#    @@cache[self.to_s][data_id] = data
  end
  def self.cache_get(data_id)
    puts 'cache_get', data_id
#    puts 'cache_get', self.inspect
    key = self.to_s + '::' + data_id.to_s
    Rails.cache.read( key.to_s )
  end
end
