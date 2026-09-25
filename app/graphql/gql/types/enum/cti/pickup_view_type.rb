# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class Cti::PickupViewType < BaseEnum
    description 'View to open for an agent who picked up a call'

    value 'userDetail', 'The detail view of the detected customer', value: :user_detail
    value 'ticketCreate', 'The ticket create screen, for the detected customer or the calling number', value: :ticket_create
  end
end
