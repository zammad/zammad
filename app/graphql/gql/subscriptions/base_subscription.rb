# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class BaseSubscription < GraphQL::Schema::Subscription
    include Gql::Concerns::HandlesAuthorization
    include Gql::Concerns::HasNestedGraphqlName

    object_class   Gql::Types::BaseObject
    field_class    Gql::Fields::BaseField
    argument_class Gql::Types::BaseArgument

    description 'Base class for all subscriptions'

    def self.authorize(_obj, ctx)
      ctx.current_user
    end

    # Add DSL to specify if a subscription is broadcastable.
    def self.broadcastable(broadcastable = nil)
      if broadcastable.nil?
        @broadcastable
      else
        @broadcastable = broadcastable
      end
    end

    def self.broadcastable?
      !!broadcastable
    end

    # Shortcut method to trigger a subscription. Just call:
    #
    #   Gql::Subscriptions::MyScubscription.trigger(
    #     self,                             # object to pass as payload,
    #     arguments: { 'filter' => arg },   # custom arguments
    #   )
    def self.trigger(object, arguments: {}, scope: nil)

      return if Setting.get('import_mode')

      ::Gql::ZammadSchema.subscriptions.trigger(
        graphql_field_name,
        arguments,
        object,
        scope: scope
      )
    end

    #
    # Default subscribe implementation that returns nothing. For this to work, all fields must have null: true.
    # Otherwise, you can provide a subscribe method in the inheriting class.
    #
    def subscribe(...)
      {}
    end

    def no_update
      # Documentation suggests to cancel updates via 'NO_UPDATE', which does not seem to work:
      # NameError: uninitialized constant GraphQL::Schema::Subscription::NO_UPDATE
      :no_update
    end

    def self.register_in_schema(schema)
      schema.field graphql_field_name, resolver: self, broadcastable: broadcastable?
    end

  end
end
