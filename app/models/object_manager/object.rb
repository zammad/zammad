# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
    { name: 'api_key', display: 'API KEY', tag: 'input', null: true, edit: true, maxlength: 32 },
    { name: 'api_ip_regexp', display: 'API IP RegExp', tag: 'input', null: true, edit: true },
    { name: 'api_ip_max', display: 'API IP Max', tag: 'input', null: true, edit: true },
  ]

=end

  def attributes(user, record = nil)
    @attributes ||= begin
      attribute_records.each_with_object([]) do |attribute_record, result|

        element = element_class.new(
          user:      user,
          attribute: attribute_record,
          record:    record,
        )

        next if !element.visible?

        result.push element.data
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
      ).order('position ASC, name ASC')
    end
  end

  def object
    @object ||= ObjectLookup.by_name(object_name)
  end

  def element_class
    @element_class ||= ObjectManager::Element.for_object(object_name)
  end
end
