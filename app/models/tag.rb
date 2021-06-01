# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Tag < ApplicationModel
  include Tag::WritesToTicketHistory
  include HasTransactionDispatcher

  belongs_to :tag_object, class_name: 'Tag::Object', optional: true
  belongs_to :tag_item,   class_name: 'Tag::Item', optional: true

  # the noop is needed since Layout/EmptyLines detects
  # the block commend below wrongly as the measurement of
  # the wanted indentation of the rubocop re-enabling above
  def noop; end

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
    data[:item].strip!

    # lookups
    if data[:object]
      tag_object_id = Tag::Object.lookup_by_name_and_create(data[:object]).id
    end
    if data[:item]
      tag_item_id = Tag::Item.lookup_by_name_and_create(data[:item]).id
    end

    # return if duplicate
    current_tags = tag_list(data)
    return true if current_tags.include?(data[:item])

    # create history
    Tag.create(
      tag_object_id: tag_object_id,
      tag_item_id:   tag_item_id,
      o_id:          data[:o_id],
      created_by_id: data[:created_by_id],
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
      data[:item].strip!
      data[:tag_item_id] = Tag::Item.lookup_by_name_and_create(data[:item]).id
    end

    # create history
    result = Tag.where(
      tag_object_id: data[:tag_object_id],
      tag_item_id:   data[:tag_item_id],
      o_id:          data[:o_id],
    )
    result.each(&:destroy)

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

tag list for certain object

  tags = Tag.tag_list(
    object: 'Ticket',
    o_id: ticket.id,
  )

returns

  ['tag 1', 'tag2', ...]

=end

  def self.tag_list(data)
    Tag.joins(:tag_item, :tag_object)
       .where(o_id: data[:o_id], tag_objects: { name: data[:object] })
       .order(:id)
       .pluck('tag_items.name')
  end
end
