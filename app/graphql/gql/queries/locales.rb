# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Locales < BaseQuery

    description 'Locales available in the system'

    type [Gql::Types::LocaleType, { null: false }], null: false

    def resolve(...)
      Locale.all
    end

  end
end
