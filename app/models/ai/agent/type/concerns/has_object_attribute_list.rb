# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module AI::Agent::Type::Concerns::HasObjectAttributeList
  extend ActiveSupport::Concern

  included do
    class_attribute :object_attribute_data_types
    class_attribute :object_attribute_object_name
    class_attribute :object_attribute_exclude_internal
  end

  class_methods do
    def object_attribute_list_data_types(*data_types)
      self.object_attribute_data_types = data_types
    end

    def object_attribute_list_object_name(object_name)
      self.object_attribute_object_name = object_name
    end

    def object_attribute_list_exclude_internal(exclude)
      self.object_attribute_exclude_internal = exclude.nil? || exclude
    end
  end

  def object_attribute_list
    @object_attribute_list ||= fetch_object_attribute_list
  end

  def object_attributes_available?
    object_attribute_list.present?
  end

  private

  # Instance method for fetching object manager attributes as options
  def fetch_object_attribute_list
    return [] if self.class.object_attribute_data_types.blank? || self.class.object_attribute_object_name.blank?

    attributes = ObjectManager::Attribute.where(
      object_lookup_id: ObjectLookup.by_name(self.class.object_attribute_object_name),
      data_type:        self.class.object_attribute_data_types,
      active:           true
    )

    if self.class.object_attribute_exclude_internal
      attributes = attributes.where(editable: true)
    end

    attributes.map do |attribute|
      {
        value: attribute.name,
        name:  attribute.display
      }
    end

  end
end
