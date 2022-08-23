# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

#
# Adds a new field argument `authorize` that can be used to hide field contents.
#   It can receive either an array of required permissions, or a method name (symbol) to call.
#
#   # Restrict a field to admin permission only:
#   field :my_field, Gql::Types::MyType, authorize: ['admin.*']
#
#   # Restrict a field by authorizing the parent object via Pundit:
#   field :my_field, Gql::Types::MyType, authorize: :by_pundit
#
#   # Restrict a field by calling a custom method on the parent object:
#   field :my_field, Gql::Types::MyType, authorize: :by_my_custom_logic
#
# See also `Gql::Concerns::CanAuthorizeFields`.
module Gql::Concerns::SkipsUnauthorizedFields
  extend ActiveSupport::Concern

  included do

    attr_reader :authorize

    def initialize(*args, authorize: nil, **kwargs, &block)
      if authorize && !kwargs[:null].nil? && !kwargs[:null]
        raise 'Authorized fields must be nullable.' # rubocop:disable Zammad/DetectTranslatableString
      end

      @authorize = authorize
      super(*args, **kwargs, &block)
    end

    def resolve(object, args, context)

      if authorize
        if authorize.is_a?(Array)
          return nil if !object.by_permissions(authorize)
        elsif !object.send(authorize)
          return nil
        end
      end

      super(object, args, context)
    end
  end
end
