# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class BaseEnum < GraphQL::Schema::Enum
    include Gql::Concern::HasNestedGraphqlName
  end
end
