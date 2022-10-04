# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class PublicLinkType < Gql::Types::BaseObject
    include Gql::Concerns::IsModelObject

    description 'Public links available in the system'

    field :link, String, null: false
    field :title, String, null: false
    field :description, String
    field :new_tab, Boolean, null: false
  end
end
