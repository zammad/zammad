class Observer::Ticket::Notification::BackgroundJob
  def initialize(params)
    @ticket_id  = params[:ticket_id]
    @article_id = params[:article_id]
    @type       = params[:type]
    @data       = params[:data]
  end
  def perform
    ticket  = Ticket.find(@ticket_id)
    article = Ticket::Article.find(@article_id)
    data    = @data

    # find recipients
    recipients = []

    # group of agents to work on
    if data[:recipient] == 'group'
      recipients = ticket.agent_of_group()

      # owner
    elsif data[:recipient] == 'owner'
      if ticket.owner_id != 1
        recipients.push ticket.owner
      end

      # customer
    elsif data[:recipient] == 'customer'
      if ticket.customer_id != 1
        # temporarily disabled
        #        recipients.push ticket.customer
      end

      # owner or group of agents to work on
    elsif data[:recipient] == 'to_work_on'
      if ticket.owner_id != 1
        recipients.push ticket.owner
      else
        recipients = ticket.agent_of_group()
      end
    end

    # send notifications
    recipient_list = ''
    notification_subject = ''
    recipients.each do |user|
      OnlineNotification.add(
        :type             => @type,
        :object           => 'Ticket',
        :o_id             => ticket.id,
        :seen             => false,
        :created_by_id    => article.created_by_id || 1,
        :user_id          => user.id,
      )

      next if !user.email || user.email == ''

      # add recipient_list
      if recipient_list != ''
        recipient_list += ','
      end
      recipient_list += user.email.to_s

      # prepare subject & body
      notification = {}
      [:subject, :body].each { |key|
        notification[key.to_sym] = NotificationFactory.build(
          :locale  => user.locale,
          :string  => data[key.to_sym],
          :objects => {
            :ticket    => ticket,
            :article   => article,
            :recipient => user,
          }
        )
      }
      notification_subject = notification[:subject]

      # rebuild subject
      notification[:subject] = ticket.subject_build( notification[:subject] )

      # send notification
      NotificationFactory.send(
        :recipient => user,
        :subject   => notification[:subject],
        :body      => notification[:body]
      )
    end

    # add history record
    if recipient_list != ''
      History.add(
        :o_id                   => ticket.id,
        :history_type           => 'notification',
        :history_object         => 'Ticket',
        :value_from             => notification_subject,
        :value_to               => recipient_list,
        :created_by_id          => article.created_by_id || 1
      )
    end
  end
end