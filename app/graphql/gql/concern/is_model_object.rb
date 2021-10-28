# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
      field :created_by, Gql::Types::UserType, null: false, description: 'User that created this record'
      field :updated_by, Gql::Types::UserType, null: false, description: 'Last user that updated this record'
    end
  end
end
