# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Queries
  class Locales < BaseQuery

    def self.requires_authentication?
      false
    end

    description 'Locales available in the system'

    type [Gql::Types::LocaleType, { null: false }], null: false

    def resolve(...)
      Locale.all
    end

  end
end
