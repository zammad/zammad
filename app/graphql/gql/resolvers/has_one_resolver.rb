# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Gql::Resolvers::HasOneResolver < GraphQL::Schema::Resolver
  include Gql::Types::Concerns::HasPunditAuthorization

  description "resolver for Rails' has_one relationship"

  def resolve
    Gql::RecordLoader
      .for(rails_definition.klass, column: rails_definition.foreign_key)
      .load(object.id)
  end

  private

  def rails_definition
    object.class.reflections[field.original_name.to_s]
  end
end
