# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Concerns::ProvidesObjectAttributeValues
  extend ActiveSupport::Concern

  included do
    argument :object_attribute_values, [Gql::Types::Input::ObjectAttributeValueInputType], required: false, description: 'Additional custom attributes (names + values)'

    transform :transform_object_attribute_values

    def transform_object_attribute_values(payload)
      payload.to_h.tap do |result|
        result.delete(:object_attribute_values)
        object_attribute_values&.each do |object_attribute|
          result[object_attribute[:name]] = object_attribute[:value]
        end
      end
    end
  end
end
