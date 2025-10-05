# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Share::Update < Service::BaseWithCurrentUser
  def execute(share:, attributes: {})
    Pundit.authorize current_user, share.ticket, :update?
    ensure_manageable!(share)

    updates = {}

    if attributes.key?(:message)
      updates[:message] = attributes[:message]
    end

    if attributes.key?(:expires_at)
      updates[:expires_at] = normalize_expires_at(attributes[:expires_at])
    end

    share.update!(updates) if updates.any?
    share.reload

    if updates.any?
      Transaction.execute(
        disable: ['Transaction::Notification'],
        user_id: current_user.id,
        interface_handle: 'application_server',
        object: 'TicketShare',
        type: 'update',
        object_id: share.id,
        changes: updates.transform_values { |v| [nil, v] },
        created_at: Time.zone.now
      ) do
        Transaction::ShareNotification.new(
          {
            object: 'TicketShare',
            type: 'update',
            object_id: share.id,
            interface_handle: 'application_server',
            changes: updates.transform_values { |v| [nil, v] },
            created_at: Time.zone.now,
            user_id: current_user.id,
          },
          { user_id: current_user.id }
        ).perform
      end
    end

    share
  end

  private

  def ensure_manageable!(share)
    return if share.shared_by_id == current_user.id || current_user.permissions?('admin')

    raise Exceptions::Forbidden, __('You can only update shares you created.')
  end

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
