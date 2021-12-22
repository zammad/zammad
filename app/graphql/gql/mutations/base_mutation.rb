# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Mutations
  # class BaseMutation < GraphQL::Schema::RelayClassicMutation
  class BaseMutation < GraphQL::Schema::Mutation
    include Gql::Concern::HandlesAuthorization

    argument_class Gql::Types::BaseArgument
    field_class    Gql::Types::BaseField
    object_class   Gql::Types::BaseObject
    # input_object_class Gql::Types::BaseInputObject

    # Override this for mutations that don't need CSRF verification.
    def self.requires_csrf_verification?
      true
    end

    def self.before_authorize(*args)
      ctx = args[-1] # This may be called with 2 or 3 params, context is last.
      # CSRF - since this is expensive it is only called by mutations.
      verify_csrf_token(ctx) if requires_csrf_verification?
    end

    def self.verify_csrf_token(ctx)
      return true if ctx[:is_graphql_introspection_generator]
      return true if Rails.env.development? && ctx[:controller].request.headers['SkipAuthenticityTokenCheck'] == 'true'

      ctx[:controller].send(:verify_csrf_token) # verify_csrf_token is private :(
    end

    def self.register_in_schema(schema)
      field_name = name.sub('Gql::Mutations::', '').gsub('::', '').camelize(:lower).to_sym
      schema.field field_name, mutation: self
    end

  end
end
