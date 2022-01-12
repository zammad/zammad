# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class PriorityType < Gql::Types::BaseObject
    include Gql::Concern::IsModelObject

    description 'Ticket priorities'

    field :name, String, null: false
    field :default_create, Boolean, null: false
    field :ui_icon, String, null: true
    field :ui_color, String, null: true
    field :note, String, null: true
    field :active, Boolean, null: false
  end
end
