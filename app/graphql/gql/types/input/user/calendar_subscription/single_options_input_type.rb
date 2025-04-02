# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class CalendarSubscription::SingleOptionsInputType < Gql::Types::BaseInputObject
    description 'Calendar subscriptions all calendars options saving'

    argument :own, Boolean, 'Defines if own tickets are included'
    argument :not_assigned, Boolean, 'Defines if not assigned tickets are included'
  end
end
