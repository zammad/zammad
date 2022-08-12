# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Concerns::ProvidesObjectAttributeValues
  extend ActiveSupport::Concern

  included do
    description 'Provides names and values for custom object fields'

    argument :object_attribute_values, [Gql::Types::Input::ObjectAttributeValueInputType], required: false, description: 'Additional custom attributes (names + values)'
  end
end
