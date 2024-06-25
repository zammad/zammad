# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class PublicLinkUpdates < BaseSubscription

    description 'Updates to public links'

    broadcastable true

    argument :screen, Gql::Types::Enum::PublicLinksScreenType, required: true, description: 'Subscribe to public links for a specific screen'

    field :public_links, [Gql::Types::PublicLinkType], description: 'Current available public links'

    def self.authorize(...)
      true # This subscription should be available for all (including unauthenticated) users.
    end

    def update(screen:)
      { public_links: PublicLink.select { |link| link[:screen].include?(screen) } }
    end
  end
end
