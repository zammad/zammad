# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Cti::PickupTargetType < Gql::Types::BaseObject
    description 'The view an agent who picked up a call lands on, decided on the server like for the old UI'

    field :view, Gql::Types::Enum::Cti::PickupViewType, null: false
    field :customer, Gql::Types::UserType, null: true, description: 'Detected customer, when any'
    field :log, Gql::Types::Cti::LogType, null: false, description: 'The picked-up call'
  end
end
