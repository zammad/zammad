# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  # class BaseMutation < GraphQL::Schema::RelayClassicMutation
  class BaseMutation < GraphQL::Schema::Mutation
    include Gql::Concerns::HandlesAuthorization
    include Gql::Concerns::HasNestedGraphqlName

    # FIXME: Remove when all mutations are using services which are taking care of this flag.
    include Gql::Mutations::Concerns::HandlesCoreWorkflow

    argument_class Gql::Types::BaseArgument
    field_class    Gql::Fields::BaseField
    object_class   Gql::Types::BaseObject
    # input_object_class Gql::Types::BaseInputObject

    description 'Base class for all mutations'

    field :errors, [Gql::Types::UserErrorType], description: 'Errors encountered during execution of the mutation.'

    # Override this for mutations that don't need CSRF verification.
    def self.requires_csrf_verification?
      true
    end

    def self.before_authorize(*args)
      ctx = args[-1] # This may be called with 2 or 3 params, context is last.
      # CSRF - since this is expensive it is only called by mutations.
      verify_csrf_token(ctx) if requires_csrf_verification?
    end

    # Require authentication by default for mutations.
    def self.authorize(_obj, ctx)
      ctx.current_user
    end

    def self.verify_csrf_token(ctx)
      return true if ctx[:is_graphql_introspection_generator]
      # Support :graphql type tests that don't use HTTP.
      return true if Rails.env.test? && !ctx[:controller]
      # Support developer workflows that need to turn off CSRF.
      return true if Rails.env.development? && ctx[:controller].request.headers['SkipAuthenticityTokenCheck'] == 'true'

      ctx[:controller].send(:verify_csrf_token) # verify_csrf_token is private :(
    end

    def self.register_in_schema(schema)
      schema.field graphql_field_name, mutation: self
    end

    def error_response(*errors)
      { errors: errors }
    end
  end
end
