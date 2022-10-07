# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concerns::IsModelObject
  extend ActiveSupport::Concern

  included do
    global_id_field :id

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'Create date/time of the record'
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'Last update date/time of the record'

    if name.eql? 'Gql::Types::UserType'
      # User model does not have relations for created_by and updated_by, so use a resolver for it.
      field :created_by, Gql::Types::UserType, description: 'User that created this record'
      field :updated_by, Gql::Types::UserType, description: 'Last user that updated this record'

      def created_by
        User.find_by(id: @object.created_by_id)
      end

      def updated_by
        User.find_by(id: @object.updated_by_id)
      end
    else
      belongs_to :created_by, Gql::Types::UserType, null: false, description: 'User that created this record'
      belongs_to :updated_by, Gql::Types::UserType, null: false, description: 'Last user that updated this record'
    end
  end

  class_methods do # rubocop:disable Metrics/BlockLength

    # Using AssociationLoader with has_many and has_and_belongs_to_many didn't work out,
    #   because the ConnectionTypes generate their own, non-preloadable queries.
    # See also https://github.com/Shopify/graphql-batch/issues/114.

    def belongs_to(association, *args, **kwargs, &block)
      given_foreign_key = kwargs.delete(:foreign_key)
      given_through_key = kwargs.delete(:through_key)

      kwargs[:resolver_method] = association_resolver(association) do
        load_belongs_to(object, association, given_foreign_key, given_through_key)
      end

      field(association, *args, **kwargs, is_dependent_field: true, &block)
    end

    def has_one(association, *args, **kwargs, &block) # rubocop:disable Naming/PredicateName
      kwargs[:resolver_method] = association_resolver(association) do
        definition = object.class.reflections[association.to_s]
        Gql::RecordLoader.for(definition.klass, column: definition.foreign_key).load(object.id)
      end

      field(association, *args, **kwargs, is_dependent_field: true, &block)
    end

    def lookup_field(name, *args, **kwargs, &block)
      method_name = (kwargs.delete(:method) || name).to_s

      kwargs[:resolver_method] = lookup_resolver(name) do
        raw_value = object.send(method_name)

        reflection_target_by_key(object, method_name)
          &.lookup(id: raw_value)
          &.name
      end

      field(name, *args, **kwargs, &block)
    end

    private

    def association_resolver(association, &block)
      define_dynamic_resolver(:"resolve_#{association}_association", &block)
    end

    def lookup_resolver(name, &block)
      define_dynamic_resolver(:"resolve_#{name}_lookup", &block)
    end

    def define_dynamic_resolver(name, &block)
      define_method(name, &block)

      name
    end
  end

  def load_belongs_to(object, association, foreign_key, through_key)
    if through_key.present?
      object_klass = ObjectLookup.by_id(object.send(through_key)).constantize
      object_id    = object.public_send(foreign_key)
    else
      definition = object.class.reflections[association.to_s]
      object_klass = definition.klass
      object_id = object.public_send(foreign_key || :"#{definition.plural_name.singularize}_id")
    end

    Gql::RecordLoader.for(object_klass).load(object_id)
  end

  def reflection_target_by_key(object, key)
    object
      .class
      .reflections
      .find { |_, elem| elem.foreign_key == key }
      &.last
      &.klass
  end
end
