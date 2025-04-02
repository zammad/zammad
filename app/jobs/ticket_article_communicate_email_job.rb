# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketArticleCommunicateEmailJob < ApplicationJob

  retry_on StandardError, attempts: 4, wait: lambda { |executions|
    executions * 25.seconds
  }

  def perform(article_id)
    record = Ticket::Article.find(article_id)

    # build subject
    ticket = Ticket.lookup(id: record.ticket_id)

    subject_prefix_mode = record.preferences[:subtype]

    subject = ticket.subject_build(record.subject, subject_prefix_mode)

    # set retry count
    record.preferences['delivery_retry'] ||= 0
    record.preferences['delivery_retry'] += 1

    # send email
    email_address = nil
    if record.preferences['email_address_id'].present?
      email_address = EmailAddress.find_by(id: record.preferences['email_address_id'])
    end

    # fallback for articles without email_address_id
    if !email_address
      if !ticket.group.email_address_id
        log_error(record, "No email address defined for group id '#{ticket.group.id}'!")
      elsif !ticket.group.email_address.channel_id
        log_error(record, "No channel defined for email_address id '#{ticket.group.email_address_id}'!")
      end
      email_address = ticket.group.email_address
    end

    # log if ref objects are missing
    if !email_address
      log_error(record, "No email address defined for group id '#{ticket.group_id}'!")
    end
    if !email_address.channel_id
      log_error(record, "No channel defined for email_address id '#{email_address.id}'!")
    end
    channel = email_address.channel

    if !channel.active
      log_error(record, "Channel defined for email address id '#{email_address.id}' is not active!", channel)
      return
    end

    notification = false
    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    if sender['name'] == 'System'
      notification = true
    end

    # get linked channel and send
    begin
      message = channel.deliver(
        {
          message_id:   record.message_id,
          in_reply_to:  record.in_reply_to,
          references:   ticket.get_references([record.message_id]),
          from:         record.from,
          to:           record.to,
          cc:           record.cc,
          subject:      subject,
          content_type: record.content_type,
          body:         record.body,
          attachments:  record.attachments,
          security:     record.preferences[:security],
        },
        notification,
      )
    rescue => e
      log_error(record, e.message, channel)
      return
    end
    if !message
      log_error(record, 'Unable to get sent email', channel)
      return
    end

    # set delivery status
    record.preferences['delivery_channel_id'] = channel.id
    record.preferences['delivery_status_message'] = nil
    record.preferences['delivery_status'] = 'success'
    record.preferences['delivery_status_date'] = Time.zone.now
    record.save!

    # store mail plain
    record.save_as_raw(message.to_s)

    # add history record
    recipient_list = ''
    %i[to cc].each do |key|

      next if !record[key]
      next if record[key] == ''

      if recipient_list != ''
        recipient_list += ','
      end
      recipient_list += record[key]
    end

    Rails.logger.info "Send email to: '#{recipient_list}' (from #{record.from})"

    return if recipient_list == ''

    History.add(
      o_id:                   record.id,
      history_type:           'email',
      history_object:         'Ticket::Article',
      related_o_id:           ticket.id,
      related_history_object: 'Ticket',
      value_from:             record.subject,
      value_to:               recipient_list,
      created_by_id:          record.created_by_id,
    )
  end

  def log_error(local_record, message, channel = nil)
    if channel
      local_record.preferences['delivery_channel_id'] = channel.id
    end
    local_record.preferences['delivery_status'] = 'fail'
    local_record.preferences['delivery_status_message'] = message.encode!('UTF-8', 'UTF-8', invalid: :replace, replace: '?')
    local_record.preferences['delivery_status_date'] = Time.zone.now
    local_record.save!
    Rails.logger.error message

    if local_record.preferences['delivery_retry'] > 3

      recipient_list = ''
      %i[to cc].each do |key|

        next if !local_record[key]
        next if local_record[key] == ''

        if recipient_list != ''
          recipient_list += ','
        end
        recipient_list += local_record[key]
      end

      # reopen ticket and notify agent
      TransactionDispatcher.reset
      UserInfo.current_user_id = 1
      Ticket::Article.create!(
        ticket_id:    local_record.ticket_id,
        content_type: 'text/plain',
        body:         "Unable to send email to '#{recipient_list}': #{message}",
        internal:     true,
        sender:       Ticket::Article::Sender.find_by(name: 'System'),
        type:         Ticket::Article::Type.find_by(name: 'note'),
        preferences:  {
          delivery_article_id_related: local_record.id,
          delivery_message:            true,
          notification:                true,
        },
      )

      ticket       = Ticket.find(local_record.ticket_id)
      ticket.state = Ticket::State.find_by(default_follow_up: true)
      ticket.save!
      TransactionDispatcher.commit
      UserInfo.current_user_id = nil
    end

    raise message
  end
end
