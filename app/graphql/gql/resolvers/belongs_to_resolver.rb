# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Gql::Resolvers::BelongsToResolver < GraphQL::Schema::Resolver
  include Gql::Types::Concerns::HasPunditAuthorization

  description "resolver for Rails' belongs_to relationship"

  def resolve
    Gql::RecordLoader
      .for(target_object_klass)
      .load(target_object_id)
  end

  private

  def target_object_klass
    if field.through_key.present?
      return ObjectLookup
        .by_id(object.send(field.through_key))
        .constantize
    end

    rails_definition
      .klass
  end

  def target_object_id
    if field.through_key.present?
      return object.public_send(field.foreign_key)
    end

    db_column = field.foreign_key || :"#{rails_definition.plural_name.singularize}_id"

    object.public_send(db_column)
  end

  def rails_definition
    object.class.reflections[field.original_name.to_s]
  end
end
