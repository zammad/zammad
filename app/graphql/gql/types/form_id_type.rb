# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class FormIdType < GraphQL::Types::BigInt
    # Zammad currenly requires FormIDs to be BigInts. Maybe this could be changed to UUIDs later on.
    description 'BigInt to identify a form.'
  end
end
