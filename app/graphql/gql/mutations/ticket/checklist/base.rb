# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::Base < BaseMutation
    description 'Base class for checklist mutations.'

    requires_enabled_setting 'checklist', error_message: __('The checklist feature is not active')
    requires_permission 'ticket.agent'
  end
end
