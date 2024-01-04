# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Gql::Resolvers::LookupResolver < GraphQL::Schema::Resolver
  include Gql::Types::Concerns::HasPunditAuthorization

  description "resolver for Rails' has_one relationship"

  def resolve
    raw_value = object.send(method_name)

    reflection_target
      &.lookup(id: raw_value)
      &.name
  end

  private

  def method_name
    @method_name ||= field.foreign_key || field.original_name
  end

  def reflection_target
    object
      .class
      .reflections
      .find { |_, elem| elem.foreign_key == method_name.to_s }
      &.last
      &.klass
  end
end
