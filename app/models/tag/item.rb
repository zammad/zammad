# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Tag::Item < ApplicationModel
  validates   :name, presence: true
  before_save :fill_namedowncase

=begin

lookup by name and create tag item

tag_item = Tag::Item.lookup_by_name_and_create('some tag')

=end

  def self.lookup_by_name_and_create(name)
    name.strip!

    tag_item = Tag::Item.lookup(name: name)
    return tag_item if tag_item

    Tag::Item.create(name: name)
  end

=begin

rename tag items

Tag::Item.rename(
  id: existing_tag_item_to_rename,
  name: 'new tag item name',
  updated_by_id: current_user.id,
)

=end

  def self.rename(data)

    new_tag_name         = data[:name].strip
    old_tag_item         = Tag::Item.find(data[:id])
    already_existing_tag = Tag::Item.lookup(name: new_tag_name)

    # check if no rename is needed
    return true if new_tag_name == old_tag_item.name

    # merge old with new tag if already existing
    if already_existing_tag

      # re-assign old tag to already existing tag
      Tag.where(tag_item_id: old_tag_item.id).each do |tag|

        # check if tag already exists on object
        if Tag.exists?(tag_object_id: tag.tag_object_id, o_id: tag.o_id, tag_item_id: already_existing_tag.id)
          Tag.tag_remove(
            tag_object_id: tag.tag_object_id,
            o_id:          tag.o_id,
            tag_item_id:   old_tag_item.id,
          )
          next
        end

        # re-assign
        tag_object = Tag::Object.lookup(id: tag.tag_object_id)
        tag.tag_item_id = already_existing_tag.id
        tag.save

        # touch reference objects
        Tag.touch_reference_by_params(
          object: tag_object.name,
          o_id:   tag.o_id,
        )
      end

      # delete not longer used tag
      old_tag_item.destroy
      return true
    end

    update_referenced_objects(old_tag_item.name, new_tag_name)

    # update new tag name
    old_tag_item.name = new_tag_name
    old_tag_item.save

    # touch reference objects
    Tag.where(tag_item_id: old_tag_item.id).each do |tag|
      tag_object = Tag::Object.lookup(id: tag.tag_object_id)
      Tag.touch_reference_by_params(
        object: tag_object.name,
        o_id:   tag.o_id,
      )
    end

    true
  end

=begin

remove tag item (destroy with reverences)

Tag::Item.remove(id)

=end

  def self.remove(id)

    # search for references, destroy and touch
    Tag.where(tag_item_id: id).each do |tag|
      tag_object = Tag::Object.lookup(id: tag.tag_object_id)
      tag.destroy
      Tag.touch_reference_by_params(
        object: tag_object.name,
        o_id:   tag.o_id,
      )
    end
    Tag::Item.find(id).destroy
    true
  end

  def fill_namedowncase
    self.name_downcase = name.downcase
    true
  end

=begin

Update referenced objects such as triggers, overviews, schedulers, and postmaster filters

Specifically, the following fields are updated:

Overview.condition
Trigger.condition   Trigger.perform
Job.condition       Job.perform
                    PostmasterFilter.perform

=end

  def self.update_referenced_objects(old_name, new_name)
    objects = Overview.all + Trigger.all + Job.all + PostmasterFilter.all

    objects.each do |object|
      changed = false
      if object.has_attribute?(:condition)
        changed |= update_condition_hash object.condition, old_name, new_name
      end
      if object.has_attribute?(:perform)
        changed |= update_condition_hash object.perform, old_name, new_name
      end
      object.save if changed
    end
  end

  def self.update_condition_hash(hash, old_name, new_name)
    changed = false
    hash.each do |key, condition|
      next if %w[ticket.tags x-zammad-ticket-tags].exclude? key
      next if condition[:value].split(', ').exclude? old_name

      condition[:value] = update_name(condition[:value], old_name, new_name)
      changed = true
    end
    changed
  end

  def self.update_name(condition, old_name, new_name)
    tags = condition.split(', ')
    return new_name if tags.size == 1

    tags = tags.map { |t| t == old_name ? new_name : t }
    tags.join(', ')
  end
end
