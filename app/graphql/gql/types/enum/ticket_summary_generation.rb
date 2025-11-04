# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class TicketSummaryGeneration < BaseEnum
    description 'Defines when the ticket summary should be generated'

    value 'global_default', 'Use global default setting.'
    value 'on_ticket_detail_opening', 'On ticket detail opening'
    value 'on_ticket_summary_sidebar_activation', 'On ticket summary sidebar activation'
  end
end
