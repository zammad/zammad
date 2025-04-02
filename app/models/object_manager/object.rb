# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ObjectManager::Object
  attr_reader :object_name

  def initialize(object_name)
    @object_name = object_name
  end

=begin

get user based list of used object attributes

  object = ObjectManager::Object.new('Ticket')
  attribute_list = object.attributes(user)

returns:

  [
    { name: 'api_key', display: 'API Key', tag: 'input', null: true, edit: true, maxlength: 32 },
    { name: 'api_ip_regexp', display: 'API IP RegExp', tag: 'input', null: true, edit: true },
    { name: 'api_ip_max', display: 'API IP Max', tag: 'input', null: true, edit: true },
  ]

=end

  def attributes(user, record = nil, data_only: true, skip_permission: false)
    @attributes ||= begin
      attribute_records.each_with_object([]) do |attribute_record, result|

        element = element_class.new(
          user:            user,
          attribute:       attribute_record,
          record:          record,
          skip_permission: skip_permission,
        )

        next if !element.visible?

        if data_only
          result.push element.data
        else
          result.push element
        end
      end
    end
  end

  private

  def attribute_records
    @attribute_records ||= begin
      ObjectManager::Attribute.where(
        object_lookup_id: object,
        active:           true,
        to_create:        false,
        to_delete:        false,
      ).reorder('position ASC, name ASC')
    end
  end

  def object
    @object ||= ObjectLookup.by_name(object_name)
  end

  def element_class
    @element_class ||= ObjectManager::Element.for_object(object_name)
  end
end
