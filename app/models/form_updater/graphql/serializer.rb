# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Serializes ActiveRecord objects to GraphQL-compatible hash structures.
# Converts field names to camelCase, adds __typename and global ID,
# and handles nested relations.
#
# Applies the same authorization as the GraphQL types: an object the current user may not see is
# not serialized, and a field scope of its policy limits the fields, relations and computed fields.
class FormUpdater::Graphql::Serializer
  # Serializes an ActiveRecord object to a GraphQL-compatible hash.
  #
  # @param object [ActiveRecord::Base] The model instance to serialize
  # @param fields [Array<String, Symbol>] Field names to include (snake_case)
  # @param current_user [User] The user the object is serialized for
  # @param relations [Hash] Nested relations to serialize, format: { relation_name: [fields] }
  # @param computed_fields [Hash] Custom/computed fields, format: { field_name: ->(obj) { value } }
  # @return [Hash, nil] Hash with camelCase keys, __typename, and global ID
  #
  # @example Basic usage
  #   FormUpdater::GraphqlSerializer.serialize(user, %w[firstname lastname email], current_user:)
  #   # => {
  #   #   "__typename" => "User",
  #   #   "id" => "gid://zammad/User/123",
  #   #   "firstname" => "John",
  #   #   "lastname" => "Doe",
  #   #   "email" => "john@example.com"
  #   # }
  #
  # @example With nested relations
  #   FormUpdater::GraphqlSerializer.serialize(
  #     user,
  #     %w[firstname lastname email],
  #     current_user:,
  #     relations: { organization: %w[name active domain_assignment] }
  #   )
  #   # => {
  #   #   "__typename" => "User",
  #   #   "id" => "gid://zammad/User/123",
  #   #   "firstname" => "John",
  #   #   "lastname" => "Doe",
  #   #   "email" => "john@example.com",
  #   #   "organization" => { ... }
  #   # }
  #
  # @example With computed fields
  #   FormUpdater::GraphqlSerializer.serialize(
  #     user,
  #     %w[firstname lastname],
  #     current_user:,
  #     computed_fields: {
  #       hasSecondaryOrganizations: ->(obj) { obj.organization_ids.present? }
  #     }
  #   )
  #   # => {
  #   #   "__typename" => "User",
  #   #   "id" => "gid://zammad/User/123",
  #   #   "firstname" => "John",
  #   #   "lastname" => "Doe",
  #   #   "hasSecondaryOrganizations" => true
  #   # }
  #
  def self.serialize(object, fields, current_user:, relations: {}, computed_fields: {})
    return nil if object.blank?

    authorization = Pundit.policy!(current_user, object).show?
    return nil if !authorization

    # Start with selected attributes
    result = object.attributes.slice(*fields.map(&:to_s).select { |field| field_authorized?(authorization, field) })

    # Convert keys to camelCase
    result = result.transform_keys { |key| key.camelize(:lower) }

    # Add GraphQL metadata
    result['__typename'] = object.class.name
    result['id'] = Gql::ZammadSchema.id_from_internal_id(object.class.name, object.id)

    # Serialize nested relations recursively
    serialize_relations(result, object, relations, authorization:, current_user:)

    # Add computed/custom fields
    serialize_computed_fields(result, object, computed_fields, authorization:)

    result
  end

  def self.serialize_relations(result, object, relations, authorization:, current_user:)
    relations.each do |relation_name, relation_fields|
      next if !field_authorized?(authorization, relation_name)

      related_object = object.public_send(relation_name)
      camel_key = relation_name.to_s.camelize(:lower)
      result[camel_key] = serialize(related_object, relation_fields, current_user:)
    end
  end
  private_class_method :serialize_relations

  def self.serialize_computed_fields(result, object, computed_fields, authorization:)
    computed_fields.each do |field_name, resolver|
      next if !field_authorized?(authorization, field_name.to_s.underscore)

      camel_key = field_name.to_s.camelize(:lower)
      result[camel_key] = resolver.call(object)
    end
  end
  private_class_method :serialize_computed_fields

  def self.field_authorized?(authorization, field)
    return true if !authorization.respond_to?(:field_authorized?)

    authorization.field_authorized?(field)
  end
  private_class_method :field_authorized?
end
