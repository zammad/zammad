# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class BaseField < GraphQL::Schema::Field
    include Gql::Concern::HandlesAuthorization
    argument_class Gql::Types::BaseArgument
  end
end
