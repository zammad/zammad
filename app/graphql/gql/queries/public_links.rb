# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class PublicLinks < BaseQuery
    description 'Fetch public links'

    argument :screen, Gql::Types::Enum::PublicLinksScreenType, required: true, description: 'Fetch public links for a specific screen'

    type [Gql::Types::PublicLinkType], null: true

    allow_public_access!

    def resolve(screen:)
      PublicLink.select { |link| link[:screen].include?(screen) }
    end
  end
end
