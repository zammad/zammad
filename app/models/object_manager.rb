# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ObjectManager

=begin

list all backend managed object

  ObjectManager.list_objects()

=end

  def self.list_objects
    %w(Ticket TicketArticle User Organization Group)
  end

=begin

list all frontend managed object

  ObjectManager.list_frontend_objects()

=end

  def self.list_frontend_objects
    %w(Ticket User Organization) #, 'Group' ]
  end

end

class ObjectManager::Attribute < ApplicationModel
  self.table_name = 'object_manager_attributes'
  belongs_to :object_lookup,   class_name: 'ObjectLookup'
  validates               :name, presence: true
  store                   :screens
  store                   :data_option

=begin

list of all attributes

  result = ObjectManager::Attribute.list_full

  result = [
    {
      name: 'some name',
      display: '...',
    }.
  ],

=end

  def self.list_full
    result = ObjectManager::Attribute.all
    attributes = []
    assets = {}
    result.each {|item|
      attribute = item.attributes
      attribute[:object] = ObjectLookup.by_id( item.object_lookup_id )
      attribute.delete('object_lookup_id')
      attributes.push attribute
    }
    attributes
  end

=begin

add a new attribute entry for an object

  ObjectManager::Attribute.add(
    :object      => 'Ticket',
    :name        => 'group_id',
    :frontend    => 'Group',
    :data_type   => 'select',
    :data_option => {
      :relation           => 'Group',
      :relation_condition => { :access => 'rw' },
      :multiple           => false,
      :null               => true,
      :translate          => false,
    },
    :editable => false,
    :active   => true,
    :screens  => {
      :create => {
        '-all-' => {
          :required => true,
        },
      },
      :edit => {
        :Agent => {
          :required => true,
        },
      },
    },
    :pending_migration => false,
    :position          => 20,
    :created_by_id     => 1,
    :updated_by_id     => 1,
    :created_at        => '2014-06-04 10:00:00',
    :updated_at        => '2014-06-04 10:00:00',
  )

=end

  def self.add(data)

    # lookups
    if data[:object]
      data[:object_lookup_id] = ObjectLookup.by_name( data[:object] )
    end
    data.delete(:object)

    # check newest entry - is needed
    result = ObjectManager::Attribute.find_by(
      object_lookup_id: data[:object_lookup_id],
      name: data[:name],
    )
    if result
      return result.update_attributes(data)
    end

    # create history
    ObjectManager::Attribute.create(data)
  end

=begin

remove attribute entry for an object

  ObjectManager::Attribute.remove(
    object: 'Ticket',
    name: 'group_id',
  )

use "force: true" to delete also not editable fields

=end

  def self.remove(data)

    # lookups
    if data[:object]
      data[:object_lookup_id] = ObjectLookup.by_name(data[:object])
    end

    # check newest entry - is needed
    result = ObjectManager::Attribute.find_by(
      object_lookup_id: data[:object_lookup_id],
      name: data[:name],
    )
    if !result
      raise "ERROR: No such field #{data[:object]}.#{data[:name]}"
    end

    if !data[:force] && !result.editable
      raise "ERROR: #{data[:object]}.#{data[:name]} can't be removed!"
    end
    result.destroy
  end

=begin

get the attribute model based on object and name

  attribute = ObjectManager::Attribute.get(
    object: 'Ticket',
    name: 'group_id',
  )

=end

  def self.get(data)

    # lookups
    if data[:object]
      data[:object_lookup_id] = ObjectLookup.by_name( data[:object] )
    end

    ObjectManager::Attribute.find_by(
      object_lookup_id: data[:object_lookup_id],
      name: data[:name],
    )
  end

=begin

get user based list of object attributes

  attribute_list = ObjectManager::Attribute.by_object('Ticket', user)

returns:

  [
    { name: 'api_key', display: 'API KEY', tag: 'input', null: true, edit: true, maxlength: 32 },
    { name: 'api_ip_regexp', display: 'API IP RegExp', tag: 'input', null: true, edit: true },
    { name: 'api_ip_max', display: 'API IP Max', tag: 'input', null: true, edit: true },
  ]

=end

  def self.by_object(object, user)

    # lookups
    if object
      object_lookup_id = ObjectLookup.by_name(object)
    end

    # get attributes in right order
    result = ObjectManager::Attribute.where(
      object_lookup_id: object_lookup_id,
      active: true,
    ).order('position ASC')
    attributes = []
    result.each {|item|
      data = {
        name: item.name,
        display: item.display,
        tag: item.data_type,
        #:null     => item.null,
      }
      if item.screens
        data[:screen] = {}
        item.screens.each {|screen, roles_options|
          data[:screen][screen] = {}
          roles_options.each {|role, options|
            if role == '-all-'
              data[:screen][screen] = options
            elsif user && user.role?(role)
              data[:screen][screen] = options
            end
          }
        }
      end
      if item.data_option
        data = data.merge(item.data_option.symbolize_keys)
      end
      attributes.push data
    }
    attributes
  end

=begin

get user based list of object attributes as hash

  attribute_list = ObjectManager::Attribute.by_object_as_hash('Ticket', user)

returns:

  {
    'api_key'       => { name: 'api_key', display: 'API KEY', tag: 'input', null: true, edit: true, maxlength: 32 },
    'api_ip_regexp' => { name: 'api_ip_regexp', display: 'API IP RegExp', tag: 'input', null: true, edit: true },
    'api_ip_max'    => { name: 'api_ip_max', display: 'API IP Max', tag: 'input', null: true, edit: true },
  }

=end

  def self.by_object_as_hash(object, user)
    list = by_object(object, user)
    hash = {}
    list.each {|item|
      hash[ item[:name] ] = item
    }
    hash
  end

end
