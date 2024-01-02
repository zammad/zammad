# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# If a user is assigned to another organization, also assign their latest tickets to it.
module User::UpdatesTicketOrganization
  extend ActiveSupport::Concern

  included do
    after_create  :user_update_ticket_organization
    after_update  :user_update_ticket_organization
  end

  private

  def user_update_ticket_organization

    return true if !Setting.get('ticket_organization_reassignment')

    # check if organization has changed
    return true if !saved_change_to_attribute?('organization_id')

    # update last 100 tickets of user
    tickets = Ticket.where(customer_id: id, organization_id: old_organization_id).limit(100)
    tickets.each do |ticket|
      next if ticket.organization_id == organization_id

      Transaction.execute(disable_notification: true, reset_user_id: true) do
        ticket.organization_id = organization_id
        ticket.save!
      end
    end
  end

  def old_organization_id
    previous_changes['organization_id'].first
  end
end
