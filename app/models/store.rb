# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Store < ApplicationModel
  load 'store/object.rb'
  load 'store/file.rb'

  store       :preferences
  belongs_to  :store_object,          class_name: 'Store::Object'
  belongs_to  :store_file,            class_name: 'Store::File'
  validates   :filename,              presence: true

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
    store_object = Store::Object.create_if_not_exists( name: data['object'] )
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

    store
  end

=begin

get attachment of object

  list = Store.list(
    :object => 'Ticket::Article',
    :o_id   => 4711,
  )

returns

  result = [store1, store2]

  store1 = {
    :size        => 94123,
    :filename    => 'image.png',
    :preferences => {
      :content_type => 'image/png',
      :content_id   => 234,
    }
  }
  store1.content # binary_string

=end

  def self.list(data)
    # search
    store_object_id = Store::Object.lookup( name: data[:object] )
    stores = Store.where( store_object_id: store_object_id, o_id: data[:o_id].to_i )
                  .order('created_at ASC, id ASC')
    stores
  end

=begin

remove attachments of object from storage

  result = Store.remove(
    :object => 'Ticket::Article',
    :o_id   => 4711,
  )

returns

  result = true

=end

  def self.remove(data)
    # search
    store_object_id = Store::Object.lookup( name: data[:object] )
    stores = Store.where( store_object_id: store_object_id )
                  .where( o_id: data[:o_id] )
                  .order('created_at ASC, id ASC')
    stores.each do |store|

      # check backend for references
      Store.remove_item( store.id )
    end
    true
  end

=begin

remove one attachment from storage

  result = Store.remove_item(store_id)

returns

  result = true

=end

  def self.remove_item(store_id)

    # check backend for references
    store = Store.find(store_id)
    files = Store.where( store_file_id: store.store_file_id )
    if files.count == 1 && files.first.id == store.id
      Store::File.find( store.store_file_id ).destroy
    end

    store.destroy
    true
  end

  def content
    file = Store::File.find_by( id: store_file_id )
    if !file
      fail "No such file #{store_file_id}!"
    end
    file.content
  end

  def provider
    file = Store::File.find_by( id: store_file_id )
    if !file
      fail "No such file #{store_file_id}!"
    end
    file.provider
  end
end
