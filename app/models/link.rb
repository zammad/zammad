# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Link < ApplicationModel

  belongs_to :link_type,   class_name: 'Link::Type', optional: true
  belongs_to :link_object, class_name: 'Link::Object', optional: true

  after_destroy :touch_link_references

  @map = {
    'normal' => 'normal',
    'parent' => 'child',
    'child'  => 'parent',
  }

=begin

  links = Link.list(
    link_object: 'Ticket',
    link_object_value: 1
  )

=end

  def self.list(data)
    linkobject = link_object_get( name: data[:link_object] )
    return if !linkobject

    items = []

    # get links for one site
    list = Link.where(
      'link_object_source_id = ? AND link_object_source_value = ?', linkobject.id, data[:link_object_value]
    )

    list.each do |item|
      link = {}
      link['link_type']         = @map[ Link::Type.find( item.link_type_id ).name ]
      link['link_object']       = Link::Object.find( item.link_object_target_id ).name
      link['link_object_value'] = item.link_object_target_value
      items.push link
    end

    # get links for the other site
    list = Link.where(
      'link_object_target_id = ? AND link_object_target_value = ?', linkobject.id, data[:link_object_value]
    )
    list.each do |item|
      link = {}
      link['link_type']         = Link::Type.find( item.link_type_id ).name
      link['link_object']       = Link::Object.find( item.link_object_source_id ).name
      link['link_object_value'] = item.link_object_source_value
      items.push link
    end

    return items if data[:user].blank?

    items.select do |item|
      authorized_item?(data[:user], item)
    end
  end

=begin

   Link.add(
    link_type: 'normal',
    link_object_source: 'Ticket',
    link_object_source_value: 6,
    link_object_target: 'Ticket',
    link_object_target_value: 31
  )

  Link.add(
    link_types_id: 12,
    link_object_source_id: 1,
    link_object_source_value: 1,
    link_object_target_id: 1,
    link_object_target_value: 1
  )

=end

  def self.add(data)

    if data.key?(:link_type)
      linktype = link_type_get(name: data[:link_type])
      data[:link_type_id] = linktype.id
      data.delete(:link_type)
    end

    if data.key?(:link_object_source)
      linkobject = link_object_get(name: data[:link_object_source])
      data[:link_object_source_id] = linkobject.id
      touch_reference_by_params(
        object: data[:link_object_source],
        o_id:   data[:link_object_source_value],
      )
      data.delete(:link_object_source)
    end

    if data.key?(:link_object_target)
      linkobject = link_object_get(name: data[:link_object_target])
      data[:link_object_target_id] = linkobject.id
      touch_reference_by_params(
        object: data[:link_object_target],
        o_id:   data[:link_object_target_value],
      )
      data.delete(:link_object_target)
    end

    Link.create(data)
  end

=begin

   Link.remove(
    link_type: 'normal',
    link_object_source: 'Ticket',
    link_object_source_value: 6,
    link_object_target: 'Ticket',
    link_object_target_value: 31
  )

=end

  def self.remove(data)
    if data.key?(:link_object_source)
      linkobject = link_object_get(name: data[:link_object_source])
      data[:link_object_source_id] = linkobject.id
    end

    if data.key?(:link_object_target)
      linkobject = link_object_get(name: data[:link_object_target])
      data[:link_object_target_id] = linkobject.id
    end

    # from one site
    if data.key?(:link_type)
      linktype = link_type_get(name: data[:link_type])
      data[:link_type_id] = linktype.id
    end
    Link.where(
      link_type_id:             data[:link_type_id],
      link_object_source_id:    data[:link_object_source_id],
      link_object_source_value: data[:link_object_source_value],
      link_object_target_id:    data[:link_object_target_id],
      link_object_target_value: data[:link_object_target_value]
    ).destroy_all

    # from the other site
    if data.key?(:link_type)
      linktype = link_type_get(name: @map[ data[:link_type] ])
      data[:link_type_id] = linktype.id
    end

    Link.where(
      link_type_id:             data[:link_type_id],
      link_object_target_id:    data[:link_object_source_id],
      link_object_target_value: data[:link_object_source_value],
      link_object_source_id:    data[:link_object_target_id],
      link_object_source_value: data[:link_object_target_value]
    ).destroy_all
  end

=begin

   Link.remove_all(
    link_object: 'Ticket',
    link_object_value: 6,
  )

=end

  def self.remove_all(data)
    if data.key?(:link_object)
      linkobject = link_object_get(name: data[:link_object])
      data[:link_object_id] = linkobject.id
    end

    Link.where(
      link_object_target_id:    data[:link_object_id],
      link_object_target_value: data[:link_object_value],
    ).destroy_all
    Link.where(
      link_object_source_id:    data[:link_object_id],
      link_object_source_value: data[:link_object_value],
    ).destroy_all

    true
  end

  def touch_link_references
    Link.touch_reference_by_params(
      object: Link::Object.lookup(id: link_object_source_id).name,
      o_id:   link_object_source_value,
    )
    Link.touch_reference_by_params(
      object: Link::Object.lookup(id: link_object_target_id).name,
      o_id:   link_object_target_value,
    )
  end

  def self.link_type_get(data)
    linktype = Link::Type.find_by(name: data[:name])
    if !linktype
      linktype = Link::Type.create(name: data[:name])
    end
    linktype
  end

  def self.link_object_get(data)
    linkobject = Link::Object.find_by(name: data[:name])
    if !linkobject
      linkobject = Link::Object.create(name: data[:name])
    end
    linkobject
  end

=begin

  Update assets according to given references list

  @param assets [Hash] hash with assets
  @param link_references [Array<Hash>] @see #list
  @return [Hash] assets including linked items

  @example Link.reduce_assets(assets, link_references)

=end

  def self.reduce_assets(assets, link_references)
    link_items = link_references
                 .map { |elem| lookup_linked_object(elem) }
                 .compact

    ApplicationModel::CanAssets.reduce(link_items, assets)
  end

  def self.lookup_linked_object(elem)
    klass = elem['link_object'].safe_constantize
    id    = elem['link_object_value']

    case klass.to_s
    when KnowledgeBase::Answer::Translation.to_s
      Setting.get('kb_active') ? klass.lookup(id: id) : nil
    else
      klass&.lookup(id: id)
    end
  end

  def self.duplicates(object1_id:, object1_value:, object2_value:, object2_id: nil)
    if !object2_id
      object2_id = object1_id
    end

    Link.joins(', links as linksb').where('
       (
         links.link_type_id = linksb.link_type_id
         AND links.link_object_source_id = linksb.link_object_source_id
         AND links.link_object_source_value = linksb.link_object_source_value
         AND links.link_object_target_id = ?
         AND linksb.link_object_target_id = ?
         AND links.link_object_target_value = ?
         AND linksb.link_object_target_value = ?
       )
       OR
       (
         links.link_type_id = linksb.link_type_id
         AND links.link_object_target_id = linksb.link_object_target_id
         AND links.link_object_target_value = linksb.link_object_target_value
         AND links.link_object_source_id = ?
         AND linksb.link_object_source_id = ?
         AND links.link_object_source_value = ?
         AND linksb.link_object_source_value = ?
       )
    ', object1_id, object2_id, object1_value, object2_value, object1_id, object2_id, object1_value, object2_value)
  end

  def self.authorized_item?(user, item)
    record = item['link_object'].constantize.lookup(id: item['link_object_value'])

    # non-ID records are not checked for authorization
    return true if record.blank?

    Pundit.authorize(user, record, :show?).present?
  rescue Pundit::NotAuthorizedError
    false
  rescue NameError, Pundit::NotDefinedError
    # NameError: no Model means no authorization check possible
    # Pundit::NotDefinedError: no Policy means no authorization check necessary
    true
  end
end
