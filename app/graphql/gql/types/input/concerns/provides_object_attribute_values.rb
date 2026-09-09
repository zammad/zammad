# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Concerns::ProvidesObjectAttributeValues
  extend ActiveSupport::Concern

  class_methods do
    # Including types must declare the ObjectManager object whose custom attributes may be
    # written through `objectAttributeValues`.
    def object_attribute_values_object
      raise NotImplementedError, "#{name} must implement .object_attribute_values_object"
    end

    # Merges the given custom attribute values into the model attributes, dropping every name
    # that is not an active, non-internal attribute of the object. Internal attributes are
    # declared as regular arguments instead, so that they pass the authorization and the
    # sanitization the individual mutations apply to them.
    #
    # This looks up the permitted names in the database, so mutations must only call it once
    # they have authorized the request.
    def merge_object_attribute_values!(value)
      custom_values = value.delete(:object_attribute_values)

      return value if custom_values.blank?

      permitted_names = permitted_object_attribute_names

      custom_values.each do |custom_value|
        next if permitted_names.exclude?(custom_value[:name])

        value[custom_value[:name]] = custom_value[:value]
      end

      value
    end

    def permitted_object_attribute_names
      ::ObjectManager::Attribute
        .for_object(object_attribute_values_object)
        .active
        .where(internal: false)
        .pluck(:name)
    end
  end

  included do
    argument :object_attribute_values, [Gql::Types::Input::ObjectAttributeValueInputType], required: false, description: 'Additional custom attributes (names + values)'

    transform :transform_object_attribute_values

    # Converts the input object into a mutable hash, but leaves the custom attribute values
    # untouched under their own key. Filtering them requires a database lookup, which must not
    # happen before the mutation has authorized the request - the mutations merge them in via
    # `merge_object_attribute_values!` instead.
    def transform_object_attribute_values(payload)
      payload.to_h
    end
  end
end
