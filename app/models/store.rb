# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'store/object'
require_dependency 'store/file'

class Store < ApplicationModel

  # rubocop:disable Rails/InverseOf
  belongs_to :store_object, class_name: 'Store::Object'
  belongs_to :store_file,   class_name: 'Store::File'
  # rubocop:enable Rails/InverseOf

  validates :filename, presence: true

  store :preferences

=begin

add an attachment to storage

  result = Store.add(
    object: 'Ticket::Article',
    o_id: 4711,
    data: binary_string,
    filename: 'filename.txt',
    preferences: {
      content_type: 'image/png',
      content_id: 234,
    }
  )

returns

  result = true

=end

  def self.add(data)
    data = data.stringify_keys

    # lookup store_object.id
    store_object = Store::Object.create_if_not_exists(name: data['object'])
    data['store_object_id'] = store_object.id

    # add to real store
    file = Store::File.add(data['data'])

    data['size'] = data['data'].to_s.bytesize
    data['store_file_id'] = file.id

    # not needed attributes
    data.delete('data')
    data.delete('object')

    # store meta data
    store = Store.create!(data)

    store
  end

=begin

get attachment of object

  list = Store.list(
    object: 'Ticket::Article',
    o_id: 4711,
  )

returns

  result = [store1, store2]

  store1 = {
    size: 94123,
    filename: 'image.png',
    preferences: {
      content_type: 'image/png',
      content_id: 234,
    }
  }
  store1.content # binary_string

=end

  def self.list(data)
    # search
    store_object_id = Store::Object.lookup(name: data[:object])
    stores = Store.where(store_object_id: store_object_id, o_id: data[:o_id].to_i)
                  .order('created_at ASC, id ASC')
    stores
  end

=begin

remove attachments of object from storage

  result = Store.remove(
    object: 'Ticket::Article',
    o_id: 4711,
  )

returns

  result = true

=end

  def self.remove(data)
    # search
    store_object_id = Store::Object.lookup(name: data[:object])
    stores = Store.where(store_object_id: store_object_id)
                  .where(o_id: data[:o_id])
                  .order('created_at ASC, id ASC')
    stores.each do |store|

      # check backend for references
      Store.remove_item(store.id)
    end
    true
  end

=begin

remove one attachment from storage

  Store.remove_item(store_id)

=end

  def self.remove_item(store_id)
    store   = Store.find(store_id)
    file_id = store.store_file_id

    # check backend for references
    files = Store.where(store_file_id: file_id)
    if files.count > 1 || files.first.id != store.id
      store.destroy!
      return true
    end

    store.destroy!
    Store::File.find(file_id).destroy!
  end

=begin

get content of file

  store = Store.find(store_id)
  content_as_string = store.content

returns

  content_as_string

=end

  def content
    file = Store::File.find_by(id: store_file_id)
    if !file
      raise "No such file #{store_file_id}!"
    end
    file.content
  end

=begin

get content of file

  store = Store.find(store_id)
  location_of_file = store.save_to_file

returns

  location_of_file

=end

  def save_to_file(path = nil)
    content
    file = Store::File.find_by(id: store_file_id)
    if !file
      raise "No such file #{store_file_id}!"
    end
    if !path
      path = Rails.root.join('tmp', filename)
    end
    ::File.open(path, 'wb') do |handle|
      handle.write file.content
    end
    path
  end

  def attributes_for_display
    slice :id, :filename, :size, :preferences
  end

  def provider
    file = Store::File.find_by(id: store_file_id)
    if !file
      raise "No such file #{store_file_id}!"
    end
    file.provider
  end
end
