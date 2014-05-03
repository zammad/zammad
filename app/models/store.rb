# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'digest/md5'


class Store < ApplicationModel
  require 'store/object'
  require 'store/file'

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

    # add to real store
    file = Store::File.add( data['data'] )

    data['size'] = data['data'].to_s.bytesize
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

  def content
    file = Store::File.where( :id => self.store_file_id ).first
    if !file
      raise "No such file #{ self.store_file_id }!"
    end
    file.content
  end

  def provider
    file = Store::File.where( :id => self.store_file_id ).first
    if !file
      raise "No such file #{ self.store_file_id }!"
    end
    file.provider
  end
end