# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::ImportArchive

  def self.run(channel, mail, transaction_params)
    return if !archivable?(channel, mail)

    # set ignore if already imported
    message_id = mail[:'message-id']
    return if !message_id

    # check if we already have imported this message
    if Ticket::Article.exists?(message_id_md5: Digest::MD5.hexdigest(message_id))
      mail[:'x-zammad-ignore'] = true
      return true
    end

    # set create time to the one given in email
    overwrite_created_at(mail)

    # do not send auto responses
    skip_auto_response(mail)

    # set ticket to a selected state, usually closed
    overwrite_ticket_state(channel, mail)

    # disable notifications and trigger
    disable_notifications_and_triggers(transaction_params)

    # find possible follow up ticket by mail references
    # we need this check here because in the follow up filter
    # this check is based on settings and we want to make sure
    # that we always check the ticket id based on the mail headers.
    Channel::Filter::FollowUpCheck.follow_up_by_md5(mail)

    true
  end

  def self.archivable?(channel, mail)
    return false if !mail[:date]

    options = channel_options(channel)
    return false if options[:archive] != true
    return false if !archivable_date_range?(channel, mail)

    true
  end

  def self.archivable_date_range?(channel, mail)
    options = channel_options(channel)
    return false if options[:archive_before].present? && options[:archive_before].to_date < mail[:date]

    true
  end

  def self.overwrite_created_at(mail)
    mail[:'x-zammad-ticket-created_at']  = mail[:date]
    mail[:'x-zammad-article-created_at'] = mail[:date]
  end

  def self.skip_auto_response(mail)
    mail[:'x-zammad-is-auto-response'] = true
  end

  def self.overwrite_ticket_state(channel, mail)
    options = channel_options(channel)

    target_state_id = Ticket::State.active.where(id: options[:archive_state_id]).pick(:id) ||
                      Ticket::State.active.by_category(:closed).pick(:id)

    mail[:'x-zammad-ticket-state_id']          = target_state_id
    mail[:'x-zammad-ticket-followup-state_id'] = target_state_id
  end

  def self.disable_notifications_and_triggers(transaction_params)
    transaction_params[:disable] += %w[
      Transaction::Notification
      Transaction::Slack
      Transaction::Trigger
    ]
  end

  def self.channel_options(channel)
    case channel
    when Channel
      channel.options.dig(:inbound, :options) || {}
    else
      channel.dig(:options, :inbound, :options) || {}
    end
  end

end
