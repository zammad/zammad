# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class UserErrorType < Gql::Types::BaseObject

    description 'Represents an error in the input of a mutation.'

    field :message, String, null: false
    field :field, String
    field :exception, Gql::Types::Enum::UserErrorExceptionType
  end
end
