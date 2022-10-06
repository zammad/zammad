# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations::Concerns::HandlesObjectAttributeValues
  extend ActiveSupport::Concern

  included do
    def convert_object_attribute_values(params)
      return if !params.key?(:object_attribute_values)

      params[:object_attribute_values].each do |object_attribute|
        params[object_attribute[:name]] = object_attribute[:value]
      end

      params.delete(:object_attribute_values)

      true
    end
  end
end
