# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Gql::ZammadSchema < GraphQL::Schema
  mutation(Gql::EntryPoints::Mutations)
  query(Gql::EntryPoints::Queries)
  # subscription(Gql::Types::SubscriptionType)

  # Enable batch loading
  use GraphQL::Batch

  # # Enable ActionCable and GraphQL connection
  # use GraphQL::Subscriptions::ActionCableSubscriptions

  # Union and Interface Resolution
  def self.resolve_type(_abstract_type, obj, _ctx)
    "Gql::Types::#{obj.class.name}Type".constantize
  rescue
    raise(GraphQL::RequiredImplementationMissingError)
  end

  # Relay-style Object Identification:

  # Return a string UUID for `object`
  def self.id_from_object(object, _type_definition, _query_ctx)
    object.to_gid.to_param
  end

  # Given a string UUID, find the object
  def self.object_from_id(id, _query_ctx)
    GlobalID.find(id)
  end

  def self.unauthorized_object(error)
    # Add a top-level error to the response instead of returning nil:
    raise GraphQL::ExecutionError, "An object of type #{error.type.graphql_name} was hidden due to permissions"
  end

  def self.unauthorized_field(error)
    # Add a top-level error to the response instead of returning nil:
    raise GraphQL::ExecutionError, "The field #{error.field.graphql_name} on an object of type #{error.type.graphql_name} was hidden due to permissions"
  end
end
