# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Types
  class LocaleType < Gql::Types::BaseObject
    include Gql::Concern::IsModelObject

    def self.requires_authentication?
      false
    end

    description 'Locales available in the system'

    field :locale, String, null: false
    field :alias, String, null: true, resolver_method: :resolve_alias
    field :name, String, null: false
    field :dir, String, null: false
    field :active, Boolean, null: false

    # Custom resolver is needed as there is a conflict with a built-in 'alias' method.
    def resolve_alias
      @object.alias
    end
  end
end
