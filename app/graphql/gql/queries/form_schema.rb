# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class FormSchema < BaseQuery

    description 'Return FormKit schema definition for a given form.'

    argument :form_schema_id, Gql::Types::Enum::FormSchemaIdType, required: true, description: 'Form identifier'

    type GraphQL::Types::JSON, null: false

    def resolve(form_schema_id: nil)
      form_schema_id.constantize.new(context: context).schema
    end
  end
end
