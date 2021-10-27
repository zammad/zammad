# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Types
  class BaseInputObject < GraphQL::Schema::InputObject
    argument_class Gql::Types::BaseArgument
  end
end
