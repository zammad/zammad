# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Share::Create < Service::BaseWithCurrentUser
  def execute(ticket:, group_id:, message: nil, expires_at: nil)
    Pundit.authorize current_user, ticket, :update?

    group = Group.find(group_id)

    # Prevent sharing with the ticket's own group (they already have access)
    if ticket.group_id == group.id
      raise Exceptions::UnprocessableEntity,
            __('Cannot share ticket with its own group (%s). The group already has access to this ticket.') % (group.fullname || group.name)
    end

    if ticket.shares.active_current.exists?(group_id: group.id)
      raise Exceptions::UnprocessableEntity,
            __('This ticket is already shared with group %s. Please update the existing share instead.') % (group.fullname || group.name)
    end

    share = ticket.shares.create!(
      group:        group,
      shared_by:   current_user,
      permissions: ['full'],
      message:     message,
      expires_at:  normalize_expires_at(expires_at),
      status:      'active'
    )

    # Send email notifications via Transaction system
    Transaction.execute(
      disable: ['Transaction::Notification'],
      user_id: current_user.id,
      interface_handle: 'application_server',
      object: 'TicketShare',
      type: 'create',
      object_id: share.id,
      changes: {
        'status' => [nil, 'active'],
        'group_id' => [nil, group.id],
        'shared_by_id' => [nil, current_user.id]
      },
      created_at: Time.zone.now
    ) do
      Transaction::ShareNotification.new(
        {
          object: 'TicketShare',
          type: 'create',
          object_id: share.id,
          interface_handle: 'application_server',
          changes: {
            'status' => [nil, 'active'],
            'group_id' => [nil, group.id],
            'shared_by_id' => [nil, current_user.id]
          },
          created_at: Time.zone.now,
          user_id: current_user.id,
        },
        { user_id: current_user.id }
      ).perform
    end

    share
  end

  private

  def normalize_expires_at(value)
    return if value.blank?

    date = case value
           when Date
             value
           when Time
             value.to_date
           else
             Date.parse(value.to_s)
           end

    date.end_of_day
  rescue ArgumentError
    raise Exceptions::UnprocessableEntity, __('Expiry date is invalid. Please provide a valid date.')
  end
end
