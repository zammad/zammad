# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Update < Service::BaseWithCurrentUser
  include Service::Concerns::HandlesCoreWorkflow

  def execute(ticket:, ticket_data:)

    Pundit.authorize current_user, ticket, :update?
    set_core_workflow_information(ticket_data, ::Ticket, 'edit')

    ticket.with_lock do
      ticket.update!(ticket_data)
    end

    ticket
  end
end
