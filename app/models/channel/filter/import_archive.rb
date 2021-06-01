# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::ImportArchive

  def self.run(channel, mail, transaction_params)
    return if !import_channel?(channel, mail)

    # set ignore if already imported
    message_id = mail[:'message-id']
    return if !message_id

    # check if we already have imported this message
    message_id_md5 = Digest::MD5.hexdigest(message_id)
    if Ticket::Article.exists?(message_id_md5: message_id_md5)
      mail[:'x-zammad-ignore'] = true
      return true
    end

    # set create time if given in email
    overwrite_created_at(mail)

    # do not send auto responses
    skip_auto_response(mail)

    # set ticket to closed
    ticket_closed(mail)

    # disable notifications and trigger
    disable_notifications(transaction_params)

    # find possible follow up ticket by mail references
    # we need this check here because in the follow up filter
    # this check is based on settings and we want to make sure
    # that we always check the ticket id based on the mail headers.
    Channel::Filter::FollowUpCheck.follow_up_by_md5(mail)

    true
  end

  def self.import_channel?(channel, mail)
    return false if !mail[:date]

    options = channel_options(channel)
    return false if options[:archive] != true
    return false if !import_channel_date_range?(channel, mail)

    true
  end

  def self.import_channel_date_range?(channel, mail)
    options = channel_options(channel)
    return false if options[:archive_before].present? && options[:archive_before].to_date < mail[:date]
    return false if options[:archive_till].present? && options[:archive_till].to_date < Time.now.utc

    true
  end

  def self.message_id?(mail)
    return if !mail[:'message-id']

    true
  end

  def self.overwrite_created_at(mail)
    mail[:'x-zammad-ticket-created_at'] = mail[:date]
    mail[:'x-zammad-article-created_at'] = mail[:date]
  end

  def self.skip_auto_response(mail)
    mail[:'x-zammad-is-auto-response'] = true
  end

  def self.ticket_closed(mail)
    closed_state = Ticket::State.by_category(:closed).first
    mail[:'x-zammad-ticket-state_id'] = closed_state.id
    mail[:'x-zammad-ticket-followup-state_id'] = closed_state.id
  end

  def self.disable_notifications(transaction_params)
    transaction_params[:disable] += %w[
      Transaction::Notification
      Transaction::Slack
      Transaction::Trigger
    ]
  end

  def self.channel_options(channel)
    if channel.instance_of?(Channel)
      return channel.options.dig(:inbound, :options) || {}
    end

    channel.dig(:options, :inbound, :options) || {}
  end

end
