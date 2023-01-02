# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Product::About < BaseQuery
    description 'Fetch the version of Zammad'

    type String, null: false

    def self.authorize(_obj, ctx)
      VersionPolicy.new(ctx.current_user, nil).show?
    end

    def resolve(...)
      Version.get
    end
  end
end
