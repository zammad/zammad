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

  def current_user
    @current_user ||= User.lookup(id: @item[:user_id]) || User.lookup(id: 1)
  end

  def perform
    # return if we run import mode
    return if Setting.get('import_mode')
    return if share.blank? || ticket.blank?
    return if @params[:disable_notification]
    return if @params[:send_notification] == false

    prepare_recipients_and_reasons

    # send notifications
    recipients_and_channels.each do |recipient_settings|
      send_to_single_recipient(recipient_settings)
    end

    true
  end

  def prepare_recipients_and_reasons
    # get recipients based on share type
    possible_recipients = get_recipients

    # apply notification settings filter
    recipients_reason_by_notifications_settings(possible_recipients)
  end

  def get_recipients
    recipients = []

    # Get all active agents and admins in the shared group
    group_users = User.group_access(share.group_id, 'read').select(&:active?)
    agent_users = group_users.select { |user| user.permissions?('ticket.agent') }
    
    agent_users.each do |user|
      recipients << user
    end

    # Add the user who shared the ticket if they're an agent
    if share.shared_by&.active? && share.shared_by.permissions?('ticket.agent')
      recipients << share.shared_by
    end

    # Remove duplicates and current user
    recipients.compact.uniq.reject { |user| user.id == @item[:user_id] }
  rescue => e
    Rails.logger.warn "Failed to get share recipients: #{e.message}"
    []
  end

  def recipients_reason_by_notifications_settings(possible_recipients)
    already_checked_recipient_ids = {}
    possible_recipients.each do |user|
      result = NotificationFactory::Mailer.notification_settings(user, ticket, @item[:type])
      next if !result
      next if already_checked_recipient_ids[user.id]

      already_checked_recipient_ids[user.id] = true
      @recipients_and_channels.push result
      next if recipients_reason[user.id]

      @recipients_reason[user.id] = get_reason_for_user(user)
    end
  end

  def send_to_single_recipient(recipient_settings)
    user     = recipient_settings[:user]
    channels = recipient_settings[:channels]

    # ignore user who changed it by him self via web
    return if recipient_myself?(user)

    # ignore inactive users
    return if !user.active?

    # check if today already notified (for specific notification types)
    if %w[create update revoke delete].include?(@item[:type])
      identifier = user.email.presence || user.login
      if identifier.present?
        already_notified_cutoff = Time.use_zone(Setting.get('timezone_default')) { Time.current.beginning_of_day }

        already_notified = History.where(
          history_type_id:   History.type_lookup('notification').id,
          history_object_id: History.object_lookup('Ticket').id,
          o_id:              ticket.id
        ).where('created_at > ?', already_notified_cutoff).exists?(['value_to LIKE ?', "%#{SqlHelper.quote_like(identifier)}(#{SqlHelper.quote_like(@item[:type])}:%"])
      end

      return if already_notified
    end

    blocked_in_days = user.mail_delivery_failed_blocked_days
    if blocked_in_days.positive?
      Rails.logger.info "Send no share notifications to #{user.email} because email is marked as mail_delivery_failed for #{blocked_in_days} day(s)"
      return
    end

    # create online notification
    used_channels = []
    if channels['online']
      used_channels.push 'online'

      created_by_id = @item[:user_id] || 1

      OnlineNotification.add(
        type:          get_notification_type,
        object:        'Ticket',
        o_id:          ticket.id,
        seen:          false,
        created_by_id: created_by_id,
        user_id:       user.id,
      )
      Rails.logger.debug { "sent share online notification to agent (#{@item[:type]}/#{ticket.id}/#{user.email})" }
    end

    # ignore email channel notification and empty emails
    if !channels['email'] || user.email.blank?
      add_recipient_list_to_history(ticket, user, used_channels, @item[:type])
      return
    end

    used_channels.push 'email'
    add_recipient_list_to_history(ticket, user, used_channels, @item[:type])

    # send email notification
    NotificationFactory::Mailer.notification(
      template:    'ticket_share_notification',
      user:        user,
      objects:     build_objects(user),
      message_id:  "<share.#{DateTime.current.to_fs(:number)}.#{ticket.id}.#{user.id}.#{SecureRandom.uuid}@#{Setting.get('fqdn')}>",
      references:  ticket.get_references,
      main_object: ticket,
    )
    Rails.logger.debug { "sent share email notification to agent (#{@item[:type]}/#{ticket.id}/#{user.email})" }
  rescue Channel::DeliveryError => e
    status_code = begin
      e.original_error.response.status.to_i
    rescue
      raise e
    end

    if SILENCABLE_SMTP_ERROR_CODES.any? { |elem| elem.include? status_code }
      Rails.logger.info do
        "could not send share email notification to agent (#{@item[:type]}/#{ticket.id}/#{user.email}) #{e.original_error}"
      end
      return
    end

    raise e
  end

  def recipient_myself?(user)
    return false if @params[:interface_handle] != 'application_server'
    return true if @item[:user_id] == user.id

    false
  end

  def add_recipient_list_to_history(ticket, user, channels, type)
    return if channels.blank?

    identifier     = user.email.presence || user.login
    recipient_list = "#{identifier}(#{type}:#{channels.join(',')})"

    History.add(
      o_id:           ticket.id,
      history_type:   'notification',
      history_object: 'Ticket',
      value_to:       recipient_list,
      created_by_id:  @item[:user_id] || 1
    )
  end

  def get_reason_for_user(user)
    case @item[:type]
    when 'create'
      __('You are receiving this because a ticket was shared with your group.')
    when 'update'
      __('You are receiving this because the share was updated.')
    when 'revoke'
      __('You are receiving this because the share was revoked.')
    when 'delete'
      __('You are receiving this because the share was deleted.')
    else
      __('You are receiving this because of a ticket share notification.')
    end
  end

  def build_objects(user)
    objects = {
      ticket:       ticket,
      share:        share,
      recipient:    user,
      current_user: current_user,
      changes:      human_changes(@item[:changes], ticket, user),
      reason:       recipients_reason[user.id],
      action:       @item[:type].to_s,
      url:          ticket_url
    }
    
    if @item[:user_id]
      objects[:actor] = User.find(@item[:user_id])
    end
    
    objects
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