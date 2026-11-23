# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ApplicationModel::CanLookupSearchIndexAttributes::RequestCache < ActiveSupport::CurrentAttributes
  attribute :integer_attribute_names, :object_manager_updated_at

  # To be called once before a search index document is built, so the lookups for the record and its references
  #   do not have to ask each time whether the object manager attributes were changed.
  def refresh
    updated_at = ObjectManager::Attribute.maximum('updated_at')
    return if updated_at == object_manager_updated_at

    self.object_manager_updated_at = updated_at
    self.integer_attribute_names   = {}
  end

  def integer_fields(class_name)
    self.integer_attribute_names ||= {}

    integer_attribute_names[class_name] ||= ObjectManager::Attribute.where(object_lookup: ObjectLookup.find_by(name: class_name), data_type: 'integer', editable: true).pluck(:name)
  end
end
