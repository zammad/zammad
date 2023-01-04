# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class PublicLinks < BaseQuery
    description 'Fetch public links'

    argument :screen, Gql::Types::Enum::PublicLinksScreenType, required: true, description: 'Fetch public links for a specific screen'

    type [Gql::Types::PublicLinkType], null: true

    # This query is available for all (including unauthenticated) users.
    def self.authorize(...)
      true
    end

    def resolve(screen:)
      PublicLink.all.select { |link| link[:screen].include?(screen) }
    end
  end
end
