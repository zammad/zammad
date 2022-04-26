# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class FormSchemaIdType < BaseEnum
    description 'All available form schemas'

    FormSchema::Form.forms.map(&:name).each do |form|
      # Convert to a GraphQL compatible name.
      value form.gsub('::', '__'), value: form
    end
  end
end
