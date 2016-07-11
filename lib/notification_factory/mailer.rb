class NotificationFactory::Mailer

=begin

get notification settings for user and notification type

  result = NotificationFactory::Mailer.notification_settings(user, ticket, type)

  type: create | update | reminder_reached | pending

returns

  {
    user: user,
    channels: {
      online: true,
      email: true,
    },
  }

=end

  def self.notification_settings(user, ticket, type)
    return if !user.preferences
    return if !user.preferences['notification_config']
    matrix = user.preferences['notification_config']['matrix']
    return if !matrix

    # check if group is in selecd groups
    if ticket.owner_id != user.id
      selected_group_ids = user.preferences['notification_config']['group_ids']
      if selected_group_ids
        if selected_group_ids.class == Array
          hit = nil
          if selected_group_ids.empty?
            hit = true
          elsif selected_group_ids[0] == '-' && selected_group_ids.count == 1
            hit = true
          else
            hit = false
            selected_group_ids.each { |selected_group_id|
              if selected_group_id.to_s == ticket.group_id.to_s
                hit = true
                break
              end
            }
          end
          return if !hit
        end
      end
    end
    return if !matrix[type]
    data = matrix[type]
    return if !data
    return if !data['criteria']
    channels = data['channel']
    return if !channels
    if data['criteria']['owned_by_me'] && ticket.owner_id == user.id
      return {
        user: user,
        channels: channels
      }
    end
    if data['criteria']['owned_by_nobody'] && ticket.owner_id == 1
      return {
        user: user,
        channels: channels
      }
    end
    return if !data['criteria']['no']
    {
      user: user,
      channels: channels
    }
  end

=begin

  success = NotificationFactory::Mailer.send(
    recipient:    User.find(123),
    subject:      'sime subject',
    body:         'some body',
    content_type: '', # optional, e. g. 'text/html'
    references:   ['message-id123', 'message-id456'],
    attachments:  [attachments...], # optional
  )

=end

  def self.send(data)
    sender = Setting.get('notification_sender')
    Rails.logger.info "Send notification to: #{data[:recipient][:email]} (from #{sender})"

    content_type = 'text/plain'
    if data[:content_type]
      content_type = data[:content_type]
    end

    # get active Email::Outbound Channel and send
    channel = Channel.find_by(area: 'Email::Notification', active: true)
    channel.deliver(
      {
        # in_reply_to: in_reply_to,
        from: sender,
        to: data[:recipient][:email],
        subject: data[:subject],
        references: data[:references],
        body: data[:body],
        content_type: content_type,
        attachments: data[:attachments],
      },
      true
    )
  end

=begin

  NotificationFactory::Mailer.notification(
    template: 'password_reset',
    user: User.find(2),
    objects: {
      recipient: User.find(2),
    },
    main_object: ticket.find(123), # optional
    references: ['message-id123', 'message-id456'],
    standalone: true, # default: false - will send header & footer
    attachments: [attachments...], # optional
  )

=end

  def self.notification(data)

    # get subject
    result = NotificationFactory::Mailer.template(
      template: data[:template],
      locale: data[:user][:preferences][:locale],
      objects: data[:objects],
      standalone: data[:standalone],
    )

    # rebuild subject
    if data[:main_object] && data[:main_object].respond_to?(:subject_build)
      result[:subject] = data[:main_object].subject_build(result[:subject])
    end

    NotificationFactory::Mailer.send(
      recipient: data[:user],
      subject: result[:subject],
      body: result[:body],
      content_type: 'text/html',
      references: data[:references],
      attachments: data[:attachments],
    )
  end

=begin

get count of already sent notifications

  count = NotificationFactory::Mailer.already_sent?(ticket, recipient_user, type)

retunes

  8

=end

  def self.already_sent?(ticket, recipient, type)
    result = ticket.history_get()
    count  = 0
    result.each { |item|
      next if item['type'] != 'notification'
      next if item['object'] != 'Ticket'
      next if item['value_to'] !~ /#{recipient.email}/i
      next if item['value_to'] !~ /#{type}/i
      count += 1
    }
    count
  end

=begin

  result = NotificationFactory::Mailer.template(
    template: 'password_reset',
    locale: 'en-us',
    objects:  {
      recipient: User.find(2),
    },
  )

  result = NotificationFactory::Mailer.template(
    templateInline: "Invitation to <%= c 'product_name' %> at <%= c 'fqdn' %>",
    locale: 'en-us',
    objects:  {
      recipient: User.find(2),
    },
  )

only raw subject/body

  result = NotificationFactory::Mailer.template(
    template: 'password_reset',
    locale: 'en-us',
    objects:  {
      recipient: User.find(2),
    },
    raw: true, # will not add application template
    standalone: true, # default: false - will send header & footer
  )

returns

  {
    subject: 'some subject',
    body: 'some body',
  }

=end

  def self.template(data)

    if data[:templateInline]
      return NotificationFactory::Template.new(data[:objects], data[:locale], data[:templateInline], false).render
    end

    template = NotificationFactory.template_read(
      locale: data[:locale] || 'en',
      template: data[:template],
      format: 'html',
      type: 'mailer',
    )

    message_subject = NotificationFactory::Template.new(data[:objects], data[:locale], template[:subject], false).render
    message_body = NotificationFactory::Template.new(data[:objects], data[:locale], template[:body]).render

    if !data[:raw]
      application_template = NotificationFactory.application_template_read(
        format: 'html',
        type: 'mailer',
      )
      data[:objects][:message] = message_body
      data[:objects][:standalone] = data[:standalone]
      message_body = NotificationFactory::Template.new(data[:objects], data[:locale], application_template).render
    end
    {
      subject: message_subject,
      body: message_body,
    }
  end

end
