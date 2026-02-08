# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  # class BaseMutation < GraphQL::Schema::RelayClassicMutation
  class BaseMutation < GraphQL::Schema::Mutation
    include Gql::Concerns::HandlesAuthorization
    include Gql::Concerns::HandlesSettingCheck
    include Gql::Concerns::HasNestedGraphqlName

    # FIXME: Remove when all mutations are using services which are taking care of this flag.
    include Gql::Mutations::Concerns::HandlesCoreWorkflow

    argument_class Gql::Types::BaseArgument
    field_class    Gql::Fields::BaseField
    object_class   Gql::Types::BaseObject
    # input_object_class Gql::Types::BaseInputObject

    description 'Base class for all mutations'

    field :errors, [Gql::Types::UserErrorType], description: 'Errors encountered during execution of the mutation.'

    # Set this to false for mutations that don't need CSRF verification.
    class_attribute :requires_csrf_verification, default: true

    def ready?(...)
      throttle_if_needed!(...)
      verify_csrf_token_if_needed!

      super
    end

    # Override this for mutations that need throttling.
    def throttle_if_needed!(...)
      # no-op
    end

    def verify_csrf_token_if_needed!
      return if !requires_csrf_verification?

      verify_csrf_token!
    end

    def verify_csrf_token!
      return true if context[:is_graphql_introspection_generator]
      # Support :graphql type tests that don't use HTTP.
      return true if Rails.env.test? && !context[:controller]
      # Support developer workflows that need to turn off CSRF.
      return true if Rails.env.development? && context[:controller].request.headers['SkipAuthenticityTokenCheck'] == 'true'

      context[:controller].send(:verify_csrf_token) # verify_csrf_token is private :(
    end

    def self.register_in_schema(schema)
      schema.field graphql_field_name, mutation: self
    end

    def self.skip_csrf_verification!
      self.requires_csrf_verification = false
    end

    # Generate a response with user errors
    #
    #   error_response({ message: 'Helpful error message.', field: 'error_field' }, ...)
    #
    def error_response(*errors)
      { errors: errors }
    end
  end
end
