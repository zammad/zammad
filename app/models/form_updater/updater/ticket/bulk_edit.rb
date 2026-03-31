# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::Ticket::BulkEdit < FormUpdater::Updater
  include FormUpdater::Concerns::ChecksCoreWorkflow

  core_workflow_screen 'overview_bulk'

  def self.required_permissions
    %w[ticket.agent]
  end

  def object_type
    ::Ticket
  end

  private

  def perform_payload
    payload = super

    # Add ticket_ids to params for CoreWorkflow to determine common owners
    return payload if meta.dig(:additional_data, 'ticketIds').nil?

    payload['params']['ticket_ids'] = meta.dig(:additional_data, 'ticketIds')

    payload
  end
end
