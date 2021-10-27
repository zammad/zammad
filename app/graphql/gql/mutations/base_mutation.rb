# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Mutations
  # class BaseMutation < GraphQL::Schema::RelayClassicMutation
  class BaseMutation < GraphQL::Schema::Mutation
    include Gql::Concern::HandlesAuthorization
    argument_class Gql::Types::BaseArgument
    field_class Gql::Types::BaseField
    # input_object_class Gql::Types::BaseInputObject
    object_class Gql::Types::BaseObject
  end
end
