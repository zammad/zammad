# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class NotificationFactory::Mailer

=begin

get notification settings for user and notification type

  result = NotificationFactory::Mailer.notification_settings(user, ticket, type)

  type: create | update | reminder_reached | escalation (escalation_warning)

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

    # map types if needed
    map = {
      'escalation_warning' => 'escalation'
    }
    if map[type]
      type = map[type]
    end

    # this cache will optimize the preference catch performance
    # because of the yaml deserialization its pretty slow
    # on many tickets you we cache it.
    user_preferences = Cache.read("NotificationFactory::Mailer.notification_settings::#{user.id}")
    if user_preferences.blank?
      user_preferences = user.preferences

      Cache.write("NotificationFactory::Mailer.notification_settings::#{user.id}", user_preferences, expires_in: 20.seconds)
    end

    return if !user_preferences
    return if !user_preferences['notification_config']

    matrix = user_preferences['notification_config']['matrix']
    return if !matrix

    owned_by_nobody = false
    owned_by_me = false
    subscribed = false
    case ticket.owner_id
    when 1
      owned_by_nobody = true
    when user.id
      owned_by_me = true
    else
      # check the replacement chain of max 10
      # if the current user is in it
      check_for = ticket.owner
      10.times do
        replacement = check_for.out_of_office_agent
        break if !replacement

        check_for = replacement
        next if replacement.id != user.id

        owned_by_me = true
        break
      end
    end

    # always trigger notifications for user if he is subscribed
    if owned_by_me == false && ticket.mentions.exists?(user: user)
      subscribed = true
    end

    # check if group is in selected groups
    if !owned_by_me && !subscribed
      selected_group_ids = user_preferences['notification_config']['group_ids']
      if selected_group_ids.is_a?(Array)
        hit = nil
        if selected_group_ids.blank? || (selected_group_ids[0] == '-' && selected_group_ids.count == 1)
          hit = true
        else
          hit = false
          selected_group_ids.each do |selected_group_id|
            if selected_group_id.to_s == ticket.group_id.to_s
              hit = true
              break
            end
          end
        end
        return if !hit # no group access
      end
    end
    return if !matrix[type]

    data = matrix[type]
    return if !data
    return if !data['criteria']

    channels = data['channel']
    return if !channels

    if data['criteria']['owned_by_me'] && owned_by_me
      return {
        user:     user,
        channels: channels
      }
    end
    if data['criteria']['owned_by_nobody'] && owned_by_nobody
      return {
        user:     user,
        channels: channels
      }
    end
    if data['criteria']['subscribed'] && subscribed
      return {
        user:     user,
        channels: channels
      }
    end
    return if !data['criteria']['no']

    {
      user:     user,
      channels: channels
    }
  end

=begin

  success = NotificationFactory::Mailer.send(
    recipient:    User.find(123),
    subject:      'some subject',
    body:         'some body',
    content_type: '', # optional, e. g. 'text/html'
    message_id:   '<some_message_id@fqdn>', # optional
    references:   ['message-id123', 'message-id456'], # optional
    attachments:  [attachments...], # optional
  )

=end

  def self.send(data)
    raise Exceptions::UnprocessableEntity, "Unable to send mail to user with id #{data[:recipient][:id]} because there is no email available." if data[:recipient][:email].blank?

    sender = Setting.get('notification_sender')
    Rails.logger.debug { "Send notification to: #{data[:recipient][:email]} (from:#{sender}/subject:#{data[:subject]})" }

    content_type = 'text/plain'
    if data[:content_type]
      content_type = data[:content_type]
    end

    # get active Email::Outbound Channel and send
    channel = Channel.find_by(area: 'Email::Notification', active: true)

    if channel.blank?
      Rails.logger.info "Can't find an active 'Email::Notification' channel. Canceling notification sending."
      return false
    end

    channel.deliver(
      {
        # in_reply_to: in_reply_to,
        from:         sender,
        to:           data[:recipient][:email],
        subject:      data[:subject],
        message_id:   data[:message_id],
        references:   data[:references],
        body:         data[:body],
        content_type: content_type,
        attachments:  data[:attachments],
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
    message_id: '<some_message_id@fqdn>', # optional
    references: ['message-id123', 'message-id456'], # optional
    standalone: true, # default: false - will send header & footer
    attachments: [attachments...], # optional
  )

=end

  def self.notification(data)

    # get subject
    result = NotificationFactory::Mailer.template(
      template:   data[:template],
      locale:     data[:user][:preferences][:locale],
      objects:    data[:objects],
      standalone: data[:standalone],
    )

    # rebuild subject
    if data[:main_object].respond_to?(:subject_build)
      result[:subject] = data[:main_object].subject_build(result[:subject])
    end

    # prepare scaling of images
    if result[:body]
      result[:body] = HtmlSanitizer.dynamic_image_size(result[:body])
    end

    NotificationFactory::Mailer.send(
      recipient:    data[:user],
      subject:      result[:subject],
      body:         result[:body],
      content_type: 'text/html',
      message_id:   data[:message_id],
      references:   data[:references],
      attachments:  data[:attachments],
    )
  end

=begin

get count of already sent notifications

  count = NotificationFactory::Mailer.already_sent?(ticket, recipient_user, type)

retunes

  8

=end

  def self.already_sent?(ticket, recipient, type)
    result = ticket.history_get
    count  = 0
    result.each do |item|
      next if item['type'] != 'notification'
      next if item['object'] != 'Ticket'
      next if !item['value_to'].match?(%r{#{recipient.email}}i)
      next if !item['value_to'].match?(%r{#{type}}i)

      count += 1
    end
    count
  end

=begin

  result = NotificationFactory::Mailer.template(
    template: 'password_reset',
    locale: 'en-us',
    timezone: 'America/Santiago',
    objects:  {
      recipient: User.find(2),
    },
  )

  result = NotificationFactory::Mailer.template(
    templateInline: "Invitation to \#{config.product_name} at \#{config.fqdn}",
    locale: 'en-us',
    timezone: 'America/Santiago',
    objects:  {
      recipient: User.find(2),
    },
    quote: true, # html quoting
  )

only raw subject/body

  result = NotificationFactory::Mailer.template(
    template: 'password_reset',
    locale: 'en-us',
    timezone: 'America/Santiago',
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
      return NotificationFactory::Renderer.new(
        objects:  data[:objects],
        locale:   data[:locale],
        timezone: data[:timezone],
        template: data[:templateInline],
        escape:   data[:quote]
      ).render
    end

    template = NotificationFactory.template_read(
      locale:   data[:locale] || Locale.default,
      template: data[:template],
      format:   data[:format] || 'html',
      type:     'mailer',
    )

    message_subject = NotificationFactory::Renderer.new(
      objects:  data[:objects],
      locale:   data[:locale],
      timezone: data[:timezone],
      template: template[:subject],
      escape:   false
    ).render

    # strip off the extra newline at the end of the subject to avoid =0A suffixes (see #2726)
    message_subject.chomp!

    message_body = NotificationFactory::Renderer.new(
      objects:  data[:objects],
      locale:   data[:locale],
      timezone: data[:timezone],
      template: template[:body]
    ).render

    if !data[:raw]
      application_template = NotificationFactory.application_template_read(
        format: 'html',
        type:   'mailer',
      )
      data[:objects][:message] = message_body
      data[:objects][:standalone] = data[:standalone]
      message_body = NotificationFactory::Renderer.new(
        objects:  data[:objects],
        locale:   data[:locale],
        timezone: data[:timezone],
        template: application_template
      ).render
    end
    {
      subject: message_subject,
      body:    message_body,
    }
  end

end
