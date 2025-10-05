class Service::Ticket::Share::Revoke < Service::BaseWithCurrentUser
  def execute(share:)
    Pundit.authorize current_user, share.ticket, :update?
    ensure_manageable!(share)

    old_status = share.status
    share.update!(status: 'revoked') unless share.status == 'revoked'
    share.reload

    # Send email notifications via Transaction system
    Transaction.execute(
      disable: ['Transaction::Notification'],
      user_id: current_user.id,
      interface_handle: 'application_server',
      object: 'TicketShare',
      type: 'revoke',
      object_id: share.id,
      changes: {
        'status' => [old_status, 'revoked']
      },
      created_at: Time.zone.now
    ) do
      Transaction::ShareNotification.new(
        {
          object: 'TicketShare',
          type: 'revoke',
          object_id: share.id,
          interface_handle: 'application_server',
          changes: {
            'status' => [old_status, 'revoked']
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

  def ensure_manageable!(share)
    return if share.shared_by_id == current_user.id || current_user.permissions?('admin')

    raise Exceptions::Forbidden, __('You can only revoke shares you created.')
  end
end
