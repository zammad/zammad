# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Tag < ApplicationModel
  include Tag::WritesToTicketHistory
  include HasTransactionDispatcher

  belongs_to :tag_object, class_name: 'Tag::Object', optional: true
  belongs_to :tag_item,   class_name: 'Tag::Item', optional: true

  validates :tag_item_id, uniqueness: { scope: %i[tag_object_id o_id] }

  scope :by_tag_object, lambda { |klass|
    output = joins(:tag_object)

    next output if !klass

    output.where(tag_objects: { name: klass })
  }

  scope :by_object,         ->(id) { where(o_id: id) if id }
  scope :include_tag_items, -> { joins(:tag_item).reorder('tags.id, tag_items.name') }

  scope :related_tag_items, lambda { |id, klass|
    include_tag_items
      .by_object(id)
      .by_tag_object(klass)
  }

=begin

add tags for certain object

  Tag.tag_add(
    object: 'Ticket',
    o_id: ticket.id,
    item: 'some tag',
    created_by_id: current_user.id,
  )

=end

  def self.tag_add(data)
    data[:item] = data[:item].strip

    # return if duplicate
    return true if tags_include?(data[:item], object: data[:object], o_id: data[:o_id])

    # lookups
    if data[:object]
      tag_object_id = Tag::Object.lookup_by_name_and_create(data[:object]).id
    end
    if data[:item]
      tag_item_id = Tag::Item.lookup_by_name_and_create(data[:item]).id
    end

    # create history
    Tag.create(
      tag_object_id: tag_object_id,
      tag_item_id:   tag_item_id,
      o_id:          data[:o_id],
      created_by_id: data[:created_by_id],
      sourceable:    data[:sourceable],
    )

    # touch reference
    touch_reference_by_params(data)
    true
  end

=begin

remove tags of certain object

  Tag.tag_remove(
    object: 'Ticket',
    o_id: ticket.id,
    item: 'some tag',
    created_by_id: current_user.id,
  )

or by ids

  Tag.tag_remove(
    tag_object_id: 123,
    o_id: ticket.id,
    tag_item_id: 123,
    created_by_id: current_user.id,
  )

=end

  def self.tag_remove(data)

    # lookups
    if data[:object]
      data[:tag_object_id] = Tag::Object.lookup_by_name_and_create(data[:object]).id
    else
      data[:object] = Tag::Object.lookup(id: data[:tag_object_id]).name
    end
    if data[:item]
      data[:item] = data[:item].strip
      data[:tag_item_id] = Tag::Item.lookup_by_name_and_create(data[:item]).id
    end

    # create history
    result = Tag.where(
      tag_object_id: data[:tag_object_id],
      tag_item_id:   data[:tag_item_id],
      o_id:          data[:o_id],
    )
    result.each do |item|
      item.sourceable = data[:sourceable]
      item.destroy
    end

    # touch reference
    touch_reference_by_params(data)
    true
  end

=begin

remove all tags of certain object

  Tag.tag_destroy(
    object: 'Ticket',
    o_id: ticket.id,
    created_by_id: current_user.id,
  )

=end

  def self.tag_destroy(data)

    # lookups
    if data[:object]
      data[:tag_object_id] = Tag::Object.lookup_by_name_and_create(data[:object]).id
    else
      data[:object] = Tag::Object.lookup(id: data[:tag_object_id]).name
    end

    # create history
    result = Tag.where(
      tag_object_id: data[:tag_object_id],
      o_id:          data[:o_id],
    )
    result.each(&:destroy)
    true
  end

=begin

update tags for certain object

  Tag.tag_update(
    object: 'Ticket',
    o_id: ticket.id,
    items: ['some tag', ['another tag']],
    created_by_id: current_user.id,
  )

=end

  def self.tag_update(object:, o_id:, items:, created_by_id: nil, sourceable: nil)
    given_tags = items.map(&:strip)
    old_tags   = tag_list(object: object, o_id: o_id)

    tag_object_id = Tag::Object.lookup_by_name_and_create(object).id

    added_tags   = given_tags - old_tags
    removed_tags = old_tags - given_tags

    added_tags.each do |tag_name|
      tag_item_id = Tag::Item.lookup_by_name_and_create(tag_name).id

      Tag.create(
        tag_object_id: tag_object_id,
        tag_item_id:   tag_item_id,
        o_id:          o_id,
        created_by_id: created_by_id,
        sourceable:,
      )
    end

    if removed_tags.any?
      tag_item_ids = removed_tags.map { |tag_name| Tag::Item.lookup_by_name_and_create(tag_name).id }

      Tag
        .where(
          tag_object_id: tag_object_id,
          tag_item_id:   tag_item_ids,
          o_id:          o_id,
        ).each do |item|
          item.sourceable = sourceable
          item.destroy
        end
    end

    # touch reference
    if added_tags.any? || removed_tags.any?
      touch_reference_by_params(object: object, o_id: o_id)
    end

    true
  end

=begin

tag list for certain object

  tags = Tag.tag_list(
    object: 'Ticket',
    o_id: ticket.id,
  )

returns

  ['tag 1', 'tag2', ...]

=end

  def self.tag_list(data)
    related_tag_items(data[:o_id], data[:object])
      .pluck('tag_items.name')
  end

  def self.tags_include?(tag_name, object: nil, o_id: nil)
    related_tag_items(o_id, object)
      .exists?(['LOWER(tag_items.name) = LOWER(?)', tag_name.strip])
  end

=begin

Lists references to objects with certain tag. Optionally filter by type.
Returns array containing object class name and ID.

@param tag [String] tag to lookup
@param object [String] optional name of the class to search in

@example

references = Tag.tag_references(
  tag: 'Tag',
  object: 'Ticket'
)

references # [['Ticket', 1], ['Ticket', 4], ...]

@return [Array<Array<String, Integer>>]

=end

  def self.tag_references(tag:, object: nil)
    tag_item = Tag::Item.find_by name: tag

    return [] if tag_item.nil?

    output = Tag.where(tag_item: tag_item).joins(:tag_object)

    output = output.where(tag_objects: { name: object }) if object.present?

    output.pluck(:'tag_objects.name', :o_id)
  end

  def self.tag_allowed?(name:, user_id: 1)
    return true if Setting.get('tag_new').present?
    return true if User.lookup(id: user_id).permissions?('admin.tag')

    Tag::Item.lookup(name: name).present?
  end
end
