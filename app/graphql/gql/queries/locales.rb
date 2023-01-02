# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Locales < BaseQuery

    description 'Locales available in the system'

    argument :only_active, Boolean, required: false, description: 'Fetch only active locales'

    type [Gql::Types::LocaleType, { null: false }], null: false

    def self.authorize(...)
      true # This query should be available for all (including unauthenticated) users.
    end

    def resolve(only_active: false)
      return Locale.where(active: true) if only_active

      Locale.all
    end
  end
end
