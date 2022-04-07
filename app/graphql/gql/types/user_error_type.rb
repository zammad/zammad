# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class UserErrorType < Gql::Types::BaseObject

    description 'Represents an error in the input of a mutation.'

    field :message, String, null: false
    field :field, String, null: true
  end
end
