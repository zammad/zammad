# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Fields
  class BaseField < GraphQL::Schema::Field
    include Gql::Concerns::HandlesAuthorization

    argument_class Gql::Types::BaseArgument

    # Make sure that on field resultion infrormation about 'is_dependent_field' is
    #   set (with a scope) in the context so that nested object types can access it as well.

    class DependentFieldExension < GraphQL::Schema::FieldExtension
      def resolve(object:, arguments:, context:, **_rest)
        context.scoped_set!(:is_dependent_field, true) if field.is_dependent_field
        yield(object, arguments)
      end
    end

    # Identify if this field is a nested member of an already authorized object.
    attr_reader :is_dependent_field

    def initialize(*args, **kwargs, &)

      kwargs[:extensions] ||= []
      kwargs[:extensions].push(DependentFieldExension)

      # Method 1: pass in the flag directly.
      @is_dependent_field = kwargs.delete(:is_dependent_field)

      # Method 2: set the flag automatically for connection types.
      if kwargs[:type].respond_to?(:ancestors) && kwargs[:type] < Gql::Types::BaseConnection
        @is_dependent_field = true
      end

      super
    end
  end
end

# Field handling extensions that must be also available to interfaces.
module GraphQL::Schema::Member::HasFields
  # Declare fields in passed block as 'ScopedField's.
  def scoped_fields(&)
    fields_with_class(Gql::Fields::ScopedField, &)
  end

  # Declare fields in passed block as 'InternalField's.
  def internal_fields(&)
    fields_with_class(Gql::Fields::InternalField, &)
  end

  def fields_with_class(type)
    field_class_orig = field_class
    field_class type
    yield
    field_class field_class_orig
  end
end
