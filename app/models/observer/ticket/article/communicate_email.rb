class Observer::Ticket::Article::CommunicateEmail < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # if sender is customer, do not communication
    sender = Ticket::Article::Sender.where( :id => record.ticket_article_sender_id ).first
    return 1 if sender == nil
    return 1 if sender['name'] == 'Customer'

    # only apply on emails
    type = Ticket::Article::Type.where( :id => record.ticket_article_type_id ).first
    return if type['name'] != 'email'

    # build subject
    ticket = Ticket.find(record.ticket_id)
    subject = ticket.subject_build( record.subject )

    # send email
    a = Channel::IMAP.new
    message = a.send(
      {
        :message_id  => record.message_id,
        :in_reply_to => record.in_reply_to,
        :from        => record.from,
        :to          => record.to,
        :cc          => record.cc,
        :subject     => subject,
        :body        => record.body,
        :attachments => record.attachments
      }
    )

    # store mail plain
    Store.add(
      :object      => 'Ticket::Article::Mail',
      :o_id        => record.id,
      :data        => message.to_s,
      :filename    => "ticket-#{ticket.number}-#{record.id}.eml",
      :preferences => {}
    )

    # add history record
    recipient_list = ''
    [:to, :cc].each { |key|
      if record[key] && record[key] != ''
        if recipient_list != ''
          recipient_list += ','
        end
        recipient_list += record[key]
      end
    }
    if recipient_list != ''
      History.history_create(
        :o_id                   => record.id,
        :history_type           => 'email',
        :history_object         => 'Ticket::Article',
        :related_o_id           => ticket.id,
        :related_history_object => 'Ticket',
        :value_from             => record.subject,
        :value_to               => recipient_list,
        :created_by_id          => record.created_by_id,
      )
    end
  end
end