# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Serializes ActiveRecord objects to GraphQL-compatible hash structures.
# Converts field names to camelCase, adds __typename and global ID,
# and handles nested relations.
class FormUpdater::Graphql::Serializer # rubocop:disable GraphQL/ObjectDescription
  # Serializes an ActiveRecord object to a GraphQL-compatible hash.
  #
  # @param object [ActiveRecord::Base] The model instance to serialize
  # @param fields [Array<String, Symbol>] Field names to include (snake_case)
  # @param relations [Hash] Nested relations to serialize, format: { relation_name: [fields] }
  # @param computed_fields [Hash] Custom/computed fields, format: { field_name: ->(obj) { value } }
  # @return [Hash, nil] Hash with camelCase keys, __typename, and global ID
  #
  # @example Basic usage
  #   FormUpdater::GraphqlSerializer.serialize(user, %w[firstname lastname email])
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
  def self.serialize(object, fields, relations: {}, computed_fields: {})
    return nil if object.blank?

    # Start with selected attributes
    result = object.attributes.slice(*fields.map(&:to_s))

    # Convert keys to camelCase
    result = result.transform_keys { |key| key.camelize(:lower) }

    # Add GraphQL metadata
    result['__typename'] = object.class.name
    result['id'] = Gql::ZammadSchema.id_from_internal_id(object.class.name, object.id)

    # Serialize nested relations recursively
    relations.each do |relation_name, relation_fields|
      related_object = object.public_send(relation_name)
      camel_key = relation_name.to_s.camelize(:lower)
      result[camel_key] = serialize(related_object, relation_fields)
    end

    # Add computed/custom fields
    computed_fields.each do |field_name, resolver|
      camel_key = field_name.to_s.camelize(:lower)
      result[camel_key] = resolver.call(object)
    end

    result
  end
end
