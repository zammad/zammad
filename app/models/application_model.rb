require 'cache'

class ApplicationModel < ActiveRecord::Base
  self.abstract_class = true

  after_create  :cache_delete
  after_update  :cache_delete
  after_destroy :cache_delete

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
    key = self.class.to_s + ':f:' + self.id.to_s
    Cache.delete( key.to_s )
  end
  def self.cache_set(data_id, data, full = false)
    if !full
      key = self.to_s + '::' + data_id.to_s
    else
      key = self.to_s + ':f:' + data_id.to_s
    end
    Cache.write( key.to_s, data )
  end
  def self.cache_get(data_id, full = false)
    if !full
      key = self.to_s + '::' + data_id.to_s
    else
      key = self.to_s + ':f:' + data_id.to_s
    end
    Cache.get( key.to_s )
  end

  def self.lookup(data)
    if data[:id]
#      puts "GET- + #{self.to_s}.#{data[:id].to_s}"
      cache = self.cache_get( data[:id] )
      return cache if cache

#      puts "Fillup- + #{self.to_s}.#{data[:id].to_s}"
      record = self.where( :id => data[:id] ).first
      self.cache_set( data[:id], record )
      return record
    elsif data[:name]
      cache = self.cache_get( data[:name] )
      return cache if cache

      records = self.where( :name => data[:name] )
      records.each {|record|
        if record.name == data[:name]
          self.cache_set( data[:name], record )
          return record
        end
      }
      return
    elsif data[:login]
      cache = self.cache_get( data[:login] )
      return cache if cache

      records = self.where( :login => data[:login] )
      records.each {|record|
        if record.login == data[:login]
          self.cache_set( data[:login], record )
          return record
        end
      }
      return
    else
      raise "Need name, id or login for lookup()"
    end
  end

  def self.create_if_not_exists(data)
    if data[:id]
      record = self.where( :id => data[:id] ).first
      return record if record
    elsif data[:name]
      records = self.where( :name => data[:name] )
      records.each {|record|
        return record if record.name == data[:name]
      }
    elsif data[:login]
      records = self.where( :login => data[:login] )
      records.each {|record|
        return record if record.login == data[:login]
      }
    elsif data[:locale] && data[:source]
      records = self.where( :locale => data[:locale], :source => data[:source] )
      records.each {|record|
        return record if record.source == data[:source]
      }
    end
    self.create(data)
  end

  def self.create_or_update(data)
    if data[:name]
      records = self.where( :name => data[:name] )
      records.each {|record|
        if record.name == data[:name]
          record.update_attributes( data )
          return record
        end
      }
      record = self.new( data )
      record.save
      return record
    else
      raise "Need name for create_or_update()"
    end
  end
end
