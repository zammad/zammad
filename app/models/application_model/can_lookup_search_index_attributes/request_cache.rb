# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ApplicationModel::CanLookupSearchIndexAttributes::RequestCache < ActiveSupport::CurrentAttributes
  attribute :integer_attribute_names

  def integer_fields(class_name)
    self.integer_attribute_names ||= {}

    updated_at = ObjectManager::Attribute.maximum('updated_at')
    return integer_attribute_names[class_name][:data] if integer_attribute_names[class_name].present? && integer_attribute_names[class_name][:updated_at] == updated_at

    integer_attribute_names[class_name] = {
      updated_at: updated_at,
      data:       ObjectManager::Attribute.where(object_lookup: ObjectLookup.find_by(name: class_name), data_type: 'integer', editable: true).pluck(:name),
    }
    integer_attribute_names[class_name][:data]
  end
end
