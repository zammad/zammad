# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries::Tickets::Concerns::ReturnsTicketTypeConnectionType
  extend ActiveSupport::Concern

  included do

    type Gql::Types::TicketType.connection_type, null: false

  end
end
