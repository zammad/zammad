# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Transaction::ShareNotification
  include ChecksHumanChanges

  # Following SMTP error codes will be handled gracefully.
  # They will be logged at info level only and the code will not propagate up the error.
  # Other SMTP error codes will stop processing and exit with logging it at error level.
  #
  # 4xx - temporary issues.
  # 52x - permanent receiving server errors.
  # 55x - permanent receiving mailbox errors.
  SILENCABLE_SMTP_ERROR_CODES = [400..499, 520..529, 550..559].freeze

=begin
  {
    object: 'TicketShare',
    type: 'create|update|revoke|delete',
    object_id: 123,
    interface_handle: 'application_server', # application_server|websocket|scheduler
    changes: {
      'status' => [before, now],
    },
    created_at: Time.zone.now,
    user_id: 123,
  },
=end

  attr_accessor :recipients_and_channels, :recipients_reason

  def initialize(item, params = {})
    @item                    = item
    @params                  = params
    @recipients_and_channels = []
    @recipients_reason       = {}
  end

  def share
    @share ||= TicketShare.find_by(id: @item[:object_id])
  end

  def ticket
    @ticket ||= share&.ticket
  end

  def perform
    return if share.blank? || ticket.blank?

    # check if notification should be send
    return if @params[:send_notification] == false

    # get recipients
    recipients = get_recipients

    return if recipients.blank?

    # send notification
    recipients.each do |local_recipient|
      next if local_recipient[:user_id].blank?

      user = User.find_by(id: local_recipient[:user_id])
      next if user.blank?

      # check notification settings
      notification_settings = NotificationFactory::Mailer.notification_settings(user, ticket, @item[:type])
      next if notification_settings.blank?

      # check if user wants to get notification
      next if notification_settings[:channels][:email] != true

      # check if already sent
      already_sent_count = NotificationFactory::Mailer.already_sent?(ticket, user, @item[:type])
      next if already_sent_count > 0

      # send notification
      begin
        NotificationFactory::Mailer.notification(
          template: 'ticket_share_notification',
          user:     user,
          objects:  build_objects(user),
        )

        # add to history
        ticket.history_add(
          'notification',
          "Sent share notification to #{user.email} (#{@item[:type]})",
          user.id,
          true
        )

        # create online notification
        OnlineNotification.add(
          type:          get_notification_type,
          object:        'Ticket',
          o_id:          ticket.id,
          seen:          false,
          user_id:       user.id,
          created_by_id: @params[:user_id]
        )

      rescue => e
        Rails.logger.error "Failed to send share notification to #{user.email}: #{e.message}"
        # Continue with other recipients even if one fails
      end
    end

    true
  end

  private

  def get_recipients
    recipients = []

    # Get all active agents and admins in the shared group
    group_users = Array(User.group_access(share.group_id, 'read')).select(&:active?)
    agent_users = group_users.select { |user| user.permissions?('ticket.agent') }
    
    agent_users.each do |user|
      recipients << { user_id: user.id }
    end

    # Add the user who shared the ticket if they're an agent
    if share.shared_by&.active? && share.shared_by.permissions?('ticket.agent')
      recipients << { user_id: share.shared_by_id }
    end

    # Remove duplicates and current user
    recipients.uniq { |r| r[:user_id] }.reject { |r| r[:user_id] == @params[:user_id] }
  rescue => e
    Rails.logger.warn "Failed to get share recipients: #{e.message}"
    []
  end

  def build_objects(user)
    {
      ticket:    ticket,
      share:     share,
      actor:     User.find(@params[:user_id]) if @params[:user_id],
      recipient: user,
      action:    @item[:type].to_s,
      url:       ticket_url
    }
  end

  def ticket_url
    "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#/ticket/zoom/#{ticket.id}"
  end

  def get_notification_type
    case @item[:type]
    when 'create'
      'Ticket shared with your group'
    when 'update'
      'Share updated'
    when 'revoke'
      'Share revoked'
    when 'delete'
      'Share deleted'
    else
      'Ticket share notification'
    end
  end
end
