# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Product::About < BaseQuery
    description 'Fetch the version of Zammad'

    type String, null: false

    requires_permission 'admin'

    def resolve(...)
      Version.get
    end
  end
end
