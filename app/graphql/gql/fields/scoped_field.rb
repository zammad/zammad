# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Fields

  # Represents fields that can be restricted by by Pundit 'FieldScope' results.
  class ScopedField < BaseField

    def initialize(*args, **kwargs, &)
      # Schema verification check: require nullability for scoped fields.
      if !kwargs[:null].nil? && !kwargs[:null]
        raise "The scoped field #{kwargs[:name]} must be nullable."
      end

      super
    end

    # If a field is not authorized, just return 'nil' rather than throwing a GraphQL error.
    def resolve(object, args, context)
      field_authorized?(object) ? super(object, args, context) : nil
    end

    private

    def field_authorized?(object)
      pundit_result = object.cached_pundit_authorize
      # Check if the pundit result is a 'FieldScope' object.
      pundit_result.respond_to?(:field_authorized?) ? pundit_result.field_authorized?(name) : !!pundit_result
    end
  end
end
