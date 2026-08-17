# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class IconSetType < Gql::Types::BaseScalar
    # Scalars are not namespaced automatically, and `IconSet` alone would be too
    #   generic for a schema-wide type name.
    graphql_name 'KnowledgeBaseIconSet'

    description "Icon font a knowledge base renders its category icons from; one of #{::KnowledgeBase::ICONSETS.join(', ')}"

    # A scalar rather than an enum, because GraphQL enum values may not contain
    #   dashes, which would rename `Simple-Line-Icons` on the wire. The values are
    #   used verbatim as icon sprite file names, so they must survive unchanged.
    def self.coerce_input(input_value, _context = nil)
      coerce_result(input_value)
    end

    # Kept in sync with the model validation, so the scalar cannot drift from the
    #   values the database actually accepts.
    def self.coerce_result(ruby_value, _context = nil)
      raise GraphQL::CoercionError, "#{ruby_value.inspect} is not a valid #{graphql_name}" if ::KnowledgeBase::ICONSETS.exclude?(ruby_value)

      ruby_value
    end
  end
end
