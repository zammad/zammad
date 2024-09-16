# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class MacrosUpdate < BaseSubscription
    description 'Updated macros'

    field :macro_updated, Boolean, description: 'Some macro was updated'

    def authorized?
      true
    end

    def update
      { macro_updated: true }
    end
  end
end
