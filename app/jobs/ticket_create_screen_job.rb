class TicketCreateScreenJob < ApplicationJob
  include HasActiveJobLock

  def perform
    Sessions.list.each do |client_id, data|
      next if client_id.blank?

      user_id = data&.dig(:user, 'id')
      next if user_id.blank?

      user = User.lookup(id: user_id)
      next if !user&.permissions?('ticket.agent')

      # get attributes to update
      ticket_create_attributes = Ticket::ScreenOptions.attributes_to_change(
        current_user: user,
      )

      # no data exists
      next if ticket_create_attributes.blank?

      Rails.logger.error "push ticket_create for user #{user.id}"
      Sessions.send(client_id, {
                      event: 'ticket_create_attributes',
                      data:  ticket_create_attributes,
                    })
    end
  end
end
