class ApplicationModel < ActiveRecord::Base
  self.abstract_class = true

  def cache_update(o)
#    puts 'u ' + self.class.to_s
    if self.respond_to?('cache_delete') then self.cache_delete end
#    puts 'g ' + group.class.to_s
    if o.respond_to?('cache_delete') then o.cache_delete end
  end
  def cache_delete
#    puts 'cache_delete', self.id
    key = self.class.to_s + '::' + self.id.to_s
    Rails.cache.delete( key.to_s )
  end
  def self.cache_set(data_id, data)
#    puts 'cache_set', data_id
    key = self.to_s + '::' + data_id.to_s
    Rails.cache.write( key.to_s, data )
  end
  def self.cache_get(data_id)
#    puts 'cache_get', data_id
    key = self.to_s + '::' + data_id.to_s
    Rails.cache.read( key.to_s )
  end
end
