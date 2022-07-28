# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class FormSchemaIdType < BaseEnum
    description 'All available form schemas'

    build_class_list_enum FormSchema::Form.forms
  end
end
