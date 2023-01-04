# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class LocaleType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Locales available in the system'

    field :locale, String, null: false
    field :alias, String, resolver_method: :resolve_alias
    field :name, String, null: false
    field :dir, Gql::Types::Enum::TextDirectionType, null: false
    field :active, Boolean, null: false

    # Custom resolver is needed as there is a conflict with a built-in 'alias' method.
    def resolve_alias
      @object.alias
    end
  end
end
