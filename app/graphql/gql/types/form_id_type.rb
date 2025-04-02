# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class FormIdType < GraphQL::Types::String
    description 'UUID to identify a form.'
  end
end
