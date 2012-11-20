require 'cache'

class ApplicationModel < ActiveRecord::Base
  self.abstract_class = true

  def self.param_cleanup(params)
    data = {}
    self.new.attributes.each {|item|
      if params.has_key?(item[0])
#        puts 'use ' + item[0].to_s + '-' + params[item[0]].to_s
        data[item[0].to_sym] = params[item[0]]
      end
    }

    # we do want to set this via database
    data.delete( :updated_at )
    data.delete( :created_at )
    data.delete( :updated_by_id )
    data.delete( :created_by_id )

    data
  end

  def cache_update(o)
#    puts 'u ' + self.class.to_s
    if self.respond_to?('cache_delete') then self.cache_delete end
#    puts 'g ' + group.class.to_s
    if o.respond_to?('cache_delete') then o.cache_delete end
  end
  def cache_delete
    key = self.class.to_s + '::' + self.id.to_s
    Cache.delete( key.to_s )
  end
  def self.cache_set(data_id, data)
    key = self.to_s + '::' + data_id.to_s
    Cache.write( key.to_s, data )
  end
  def self.cache_get(data_id)
    key = self.to_s + '::' + data_id.to_s
    Cache.get( key.to_s )
  end
end
