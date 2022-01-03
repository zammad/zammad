# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class BaseQuery < GraphQL::Schema::Resolver
    include Gql::Concern::HandlesAuthorization

    def self.register_in_schema(schema)
      field_name = name.sub('Gql::Queries::', '').gsub('::', '').camelize(:lower).to_sym
      schema.field field_name, resolver: self
    end

  end
end
