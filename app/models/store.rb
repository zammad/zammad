# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'digest/md5'

class Store < ApplicationModel
  store       :preferences
  belongs_to  :store_object,          :class_name => 'Store::Object'
  belongs_to  :store_file,            :class_name => 'Store::File'
  validates   :filename,              :presence => true

=begin

add an attachment to storage

  result = Store.add(
    :object       => 'Ticket::Article',
    :o_id         => 4711,
    :data         => binary_string,
    :preferences  => {
      :content_type => 'image/png',
      :content_id   => 234,
    }
  )

returns

  result = true

=end

  def self.add(data)
    data = data.stringify_keys

    # lookup store_object.id
    store_object = Store::Object.create_if_not_exists( :name => data['object'] )
    data['store_object_id'] = store_object.id

    # check if record already exists
    #    store = Store.where( :store_object_id => store_object.id, :o_id => data['o_id'],  ).first
    #    if store != nil
    #      return store
    #    end

    # check real store
    md5 = Digest::MD5.hexdigest( data['data'] )
    data['size'] = data['data'].to_s.bytesize

    file = Store::File.where( :md5 => md5 ).first

    # store attachment
    if file == nil
      file = Store::File.create(
        :data => data['data'],
        :md5  => md5,
      )
    end

    data['store_file_id'] = file.id

    # not needed attributes
    data.delete('data')
    data.delete('object')

    # store meta data
    store = Store.create(data)

    true
  end

=begin

get attachment of object

  list = Store.list(
    :object       => 'Ticket::Article',
    :o_id         => 4711,
  )

returns

  result = [store1, store2]

  store1 = {
    :size         => 94123,
    :filename     => 'image.png',
    :preferences  => {
      :content_type => 'image/png',
      :content_id   => 234,
    }
  }
  store1.content # binary_string

=end

  def self.list(data)
    # search
    store_object_id = Store::Object.lookup( :name => data[:object] )
    stores = Store.where( :store_object_id => store_object_id, :o_id => data[:o_id].to_i ).
    order('created_at ASC, id ASC')
    return stores
  end

=begin

remove an attachment to storage

  result = Store.remove(
    :object       => 'Ticket::Article',
    :o_id         => 4711,
  )

returns

  result = true

=end

  def self.remove(data)
    # search
    store_object_id = Store::Object.lookup( :name => data[:object] )
    stores = Store.where( :store_object_id => store_object_id ).
    where( :o_id => data[:o_id] ).
    order('created_at ASC, id ASC')
    stores.each do |store|

      # check backend for references
      files = Store.where( :store_file_id => store.store_file_id )
      if files.count == 1 && files.first.id == store.id
        Store::File.find( store.store_file_id ).destroy
      end

      store.destroy
    end
    return true
  end

  # get attachment
  def content
    file = Store::File.where( :id => self.store_file_id ).first
    return if !file
    if file.file_system
      return file.read_from_fs
    end
    file.data
  end
end

class Store::Object < ApplicationModel
  validates :name, :presence => true
end

class Store::File < ApplicationModel
  before_validation :add_md5
  before_create     :check_location
  after_destroy     :unlink_location

  # generate file location
  def get_locaton

    # generate directory
    base = Rails.root.to_s + '/storage/fs/'
    parts = self.md5.scan(/.{1,3}/)
    path = parts[ 1 .. 7 ].join('/') + '/'
    file = parts[ 8 .. parts.count ].join('')
    location = "#{base}/#{path}"

    # create directory if not exists
    if !File.exist?( location )
      FileUtils.mkdir_p( location )
    end
    location += file
  end

  # read file from fs
  def unlink_location
    if File.exist?( self.get_locaton )
      puts "NOTICE: storge remove '#{self.get_locaton}'"
      File.delete( self.get_locaton )
    end
  end

  # read file from fs
  def read_from_fs
    puts "read from fs #{self.get_locaton}"
    return if !File.exist?( self.get_locaton )
    data = File.open( self.get_locaton, 'rb' )
    content = data.read

    # check md5
    md5 = Digest::MD5.hexdigest( content )
    if md5 != self.md5
      raise "ERROR: Corrupt file in fs #{self.get_locaton}, md5 should be #{self.md5} but is #{md5}"
    end
    content
  end

  # write file to fs
  def write_to_fs

    # install file
    permission = '600'
    if !File.exist?( self.get_locaton )
      puts "NOTICE: storge write '#{self.get_locaton}' (#{permission})"
      file = File.new( self.get_locaton, 'wb' )
      file.write( self.data )
      file.close
    end
    File.chmod( permission.to_i(8), self.get_locaton )

    # check md5
    md5 = Digest::MD5.hexdigest( self.read_from_fs )
    if md5 != self.md5
      raise "ERROR: Corrupt file in fs #{self.get_locaton}, md5 should be #{self.md5} but is #{md5}"
    end

    true
  end

  # write file to db
  def write_to_db

    # read and check md5
    content = self.read_from_fs

    # store in database
    self.data = content
    self.save

    # check md5 against db content
    md5 = Digest::MD5.hexdigest( self.data )
    if md5 != self.md5
      raise "ERROR: Corrupt file in db #{self.get_locaton}, md5 should be #{self.md5} but is #{md5}"
    end

    true
  end

  # check database data and md5, in case fix it
  def self.db_check_md5(fix_it = nil)
    Store::File.where( :file_system => false ).each {|item|
      md5 = Digest::MD5.hexdigest( item.data )
      if md5 != item.md5
        puts "DIFF: md5 diff of Store::File.find(#{item.id}) "
        if fix_it
          item.update_attribute( :md5, md5 )
        end
      end
    }
    true
  end

  def self.move_to_fs
    Store::File.where( :file_system => false ).each {|item|
      item.write_to_fs
      item.update_attribute( :file_system, true )
      item.update_attribute( :data, nil )
    }
  end

  def self.move_to_db
    Store::File.where( :file_system => true ).each {|item|
      item.write_to_db
      item.update_attribute( :file_system, false )
      item.unlink_location
    }
  end

  private

  def check_location

    # write initial to fs if needed
    if self.file_system && self.data
      self.write_to_fs
      self.data = nil
    end
  end

  def add_md5
    if self.data && !self.md5
      self.md5 = Digest::MD5.hexdigest( self.data )
    end
  end
end