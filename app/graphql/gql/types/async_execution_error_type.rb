# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class AsyncExecutionErrorType < Gql::Types::BaseObject

    description 'Represents an error with the execution of an async job.'

    field :message, String, null: false
    field :exception, String, null: false
  end
end
