# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  module ObjectAttributeValuesInterface
    include Gql::Types::BaseInterface

    description 'Custom object fields (only editable & active)'

    scoped_fields do
      field :object_attribute_values, [Gql::Types::ObjectAttributeValueType, { null: false }]
    end

    def object_attribute_values
      return [] if !@object || !context.current_user?

      find_object_attributes.reduce([]) do |result, oa|
        result << { attribute: attribute_hash(oa.attribute), value: @object[oa.attribute[:name].to_sym], parent: @object }
      end
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
