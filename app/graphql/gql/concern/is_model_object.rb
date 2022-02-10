# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concern::IsModelObject
  extend ActiveSupport::Concern

  included do
    implements GraphQL::Types::Relay::Node
    global_id_field :id

    # Make sure that objects in subdirectories do not get only the class name as type name,
    #   but also the parent directories.
    graphql_name name.sub('Gql::Types::', '').gsub('::', '').sub(%r{Type\Z}, '')

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'Create date/time of the record'
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'Last update date/time of the record'

    if name.eql? 'Gql::Types::UserType'
      field :created_by_id, Integer, null: false, description: 'User that created this record'
      field :updated_by_id, Integer, null: false, description: 'Last user that updated this record'
    else
      belongs_to :created_by, Gql::Types::UserType, null: false, description: 'User that created this record'
      belongs_to :updated_by, Gql::Types::UserType, null: false, description: 'Last user that updated this record'
    end
  end

  class_methods do

    # Using AssociationLoader with has_many and has_and_belongs_to_many didn't work out,
    #   because the ConnectionTypes generate their own, non-preloadable queries.
    # See also https://github.com/Shopify/graphql-batch/issues/114.

    def belongs_to(association, *args, **kwargs, &block)
      kwargs[:resolver_method] = association_resolver(association) do
        definition = object.class.reflections[association.to_s]
        id = object.public_send(:"#{definition.plural_name.singularize}_id")
        Gql::RecordLoader.for(definition.klass).load(id)
      end

      field(association, *args, **kwargs, &block)
    end

    def has_one(association, *args, **kwargs, &block) # rubocop:disable Naming/PredicateName
      kwargs[:resolver_method] = association_resolver(association) do
        definition = object.class.reflections[association.to_s]
        Gql::RecordLoader.for(definition.klass, column: definition.foreign_key).load(object.id)
      end

      field(association, *args, **kwargs, &block)
    end

    private

    def association_resolver(association, &block)
      :"resolve_#{association}_association".tap do |resolver_method|
        define_method(resolver_method, &block)
      end
    end
  end
end
