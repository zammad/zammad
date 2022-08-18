# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  module ObjectAttributeValueInterface
    include Gql::Types::BaseInterface

    description 'Custom object fields (only editable & active)'
    field :object_attribute_values, [Gql::Types::ObjectAttributeValueType, { null: false }], null: false

    def object_attribute_values
      return [] if !@object || !context.current_user?

      result = []

      find_object_attributes.each do |oa|
        result << { attribute: attribute_hash(oa.attribute), value: @object[oa.attribute[:name].to_sym] }
      end

      result
    end

    def find_object_attributes
      ::ObjectManager::Object.new(@object.class.name).attributes(context.current_user, @object, data_only: false)
        .select { |oa| oa.attribute.editable }
    end

    private

    def attribute_hash(attribute)
      {
        name:        attribute[:name],
        display:     attribute[:display],
        data_type:   attribute[:data_type],
        data_option: attribute[:data_option],
      }
    end
  end
end
