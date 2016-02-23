class Observer::Ticket::Article::CommunicateEmail::BackgroundJob
  def initialize(id)
    @article_id = id
  end

  def perform
    record = Ticket::Article.find(@article_id)

    # build subject
    ticket  = Ticket.lookup(id: record.ticket_id)
    subject = ticket.subject_build(record.subject)

    # send email
    if !ticket.group.email_address_id
      fail "Can't send email, no email address definde for group id '#{ticket.group.id}'"
    elsif !ticket.group.email_address.channel_id
      fail "Can't send email, no channel definde for email_address id '#{ticket.group.email_address_id}'"
    end

    channel = ticket.group.email_address.channel

    # get linked channel and send
    message = channel.deliver(
      {
        message_id: record.message_id,
        in_reply_to: record.in_reply_to,
        references: ticket.get_references([record.message_id]),
        from: record.from,
        to: record.to,
        cc: record.cc,
        subject: subject,
        content_type: record.content_type,
        body: record.body,
        attachments: record.attachments
      }
    )

    # store mail plain
    Store.add(
      object: 'Ticket::Article::Mail',
      o_id: record.id,
      data: message.to_s,
      filename: "ticket-#{ticket.number}-#{record.id}.eml",
      preferences: {},
      created_by_id: record.created_by_id,
    )

    # add history record
    recipient_list = ''
    [:to, :cc].each { |key|

      next if !record[key]
      next if record[key] == ''

      if recipient_list != ''
        recipient_list += ','
      end
      recipient_list += record[key]
    }

    return if recipient_list == ''

    History.add(
      o_id: record.id,
      history_type: 'email',
      history_object: 'Ticket::Article',
      related_o_id: ticket.id,
      related_history_object: 'Ticket',
      value_from: record.subject,
      value_to: recipient_list,
      created_by_id: record.created_by_id,
    )
  end
end
