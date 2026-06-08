# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries::Tickets::Concerns::TakesTicketStateTypeCategory
  extend ActiveSupport::Concern

  included do

    argument :state_type_category, Gql::Types::Enum::TicketStateTypeCategoryType, required: false, description: 'Filter by state type category'

  end

end
