# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Tag < ApplicationModel
  belongs_to :tag_object,       class_name: 'Tag::Object'
  belongs_to :tag_item,         class_name: 'Tag::Item'

  # rubocop:disable Style/ClassVars
  @@cache_item = {}
  @@cache_object = {}
  # rubocop:enable Style/ClassVars

  def self.tag_add(data)

    # lookups
    if data[:object]
      tag_object_id = tag_object_lookup(data[:object])
    end
    if data[:item]
      tag_item_id = tag_item_lookup(data[:item].strip)
    end

    # return in duplicate
    current_tags = tag_list(data)
    return true if current_tags.include?(data[:item].strip)

    # create history
    Tag.create(
      tag_object_id: tag_object_id,
      tag_item_id: tag_item_id,
      o_id: data[:o_id],
      created_by_id: data[:created_by_id],
    )
    true
  end

  def self.tag_remove(data)

    # lookups
    if data[:object]
      tag_object_id = tag_object_lookup(data[:object])
    end
    if data[:item]
      tag_item_id = tag_item_lookup(data[:item].strip)
    end

    # create history
    result = Tag.where(
      tag_object_id: tag_object_id,
      tag_item_id: tag_item_id,
      o_id: data[:o_id],
    )
    result.each(&:destroy)
    true
  end

  def self.tag_list(data)
    tag_object_id_requested = tag_object_lookup(data[:object])
    tag_search = Tag.where(
      tag_object_id: tag_object_id_requested,
      o_id: data[:o_id],
    )
    tags = []
    tag_search.each {|tag|
      tags.push tag_item_lookup_id(tag.tag_item_id)
    }
    tags
  end

  def self.tag_item_lookup_id(id)

    # use cache
    return @@cache_item[id] if @@cache_item[id]

    # lookup
    tag_item = Tag::Item.find(id)
    @@cache_item[id] = tag_item.name
    tag_item.name
  end

  def self.tag_item_lookup(name)

    # use cache
    return @@cache_item[name] if @@cache_item[name]

    # lookup
    tag_items = Tag::Item.where(name: name)
    tag_items.each {|tag_item|
      next if tag_item.name != name
      @@cache_item[name] = tag_item.id
      return tag_item.id
    }

    # create
    tag_item = Tag::Item.create(name: name)
    @@cache_item[name] = tag_item.id
    tag_item.id
  end

  def self.tag_object_lookup_id(id)

    # use cache
    return @@cache_object[id] if @@cache_object[id]

    # lookup
    tag_object = Tag::Object.find(id)
    @@cache_object[id] = tag_object.name
    tag_object.name
  end

  def self.tag_object_lookup(name)

    # use cache
    return @@cache_object[name] if @@cache_object[name]

    # lookup
    tag_object = Tag::Object.find_by(name: name)
    if tag_object
      @@cache_object[name] = tag_object.id
      return tag_object.id
    end

    # create
    tag_object = Tag::Object.create(name: name)
    @@cache_object[name] = tag_object.id
    tag_object.id
  end

  class Object < ActiveRecord::Base
  end

  class Item < ActiveRecord::Base
    before_save :fill_namedowncase

    def fill_namedowncase
      self.name_downcase = name.downcase
    end

  end

end
