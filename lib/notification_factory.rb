module NotificationFactory

=begin

get notification settings for user and notification type

  result = NotificationFactory.notification_settings(user, ticket, type)

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
            selected_group_ids.each {|selected_group_id|
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

# deprecated, will be removed with 2.0

  result_string = NotificationFactory.build(
    string:  'Hi #{recipient.firstname},',
    objects: {
      ticket   : ticket,
      recipient: User.find(2),
    },
    locale: 'en',
  )

=end

  def self.build(data)

    data[:string].gsub!( / \#\{ \s* ( .+? ) \s* \} /xm ) { |placeholder|

      # store possible callback to work with
      # and check if it's valid for execution
      original_string = $&
      callback        = $1

      object_name   = nil
      object_method = nil

      if callback =~ /\A ( [\w]+ )\.( [\w\.]+ ) \z/x
        object_name   = $1
        object_method = $2
      end

      # do validaton, ignore some methodes
      if callback =~ /(`|\.(|\s*)(save|destroy|delete|remove|drop|update\(|update_att|create\(|new|all|where|find))/i
        placeholder = "#{original_string} (not allowed)"

      # get value based on object_name and object_method
      elsif object_name && object_method

        # use config params
        if object_name == 'config'
          placeholder = Setting.get(object_method)

        # if object_name dosn't exist
        elsif !data[:objects][object_name.to_sym]
          placeholder = "\#{#{object_name} / no such object}"
        else
          value            = nil
          object_refs      = data[:objects][object_name.to_sym]
          object_methods   = object_method.split('.')
          object_methods_s = ''
          object_methods.each {|method|
            if object_methods_s != ''
              object_methods_s += '.'
            end
            object_methods_s += method

            # if method exists
            if !object_refs.respond_to?( method.to_sym )
              value = "\#{#{object_name}.#{object_methods_s} / no such method}"
              break
            end
            object_refs = object_refs.send( method.to_sym )

            # add body quote
            next if object_name != 'article'
            next if method != 'body'

            next if data[:objects][:article].content_type != 'text/html'

            object_refs = object_refs.html2text.chomp
          }
          placeholder = if !value
                          object_refs
                        else
                          value
                        end
        end
      end
      placeholder
    }

    # translate
    data[:string].gsub!( /i18n\((|.+?)\)/ ) {
      string      = $1
      locale      = data[:locale] || 'en'

      Translation.translate( locale, string )
    }

    data[:string]
  end

=begin

  success = NotificationFactory.send(
    recipient:    User.find(123),
    subject:      'sime subject',
    body:         'some body',
    content_type: '', # optional, e. g. 'text/html'
    references:   ['message-id123', 'message-id456'],
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
      },
      true
    )
  end

=begin

  NotificationFactory.notification(
    template: 'password_reset',
    user: User.find(2),
    objects: {
      recipient: User.find(2),
    },
    main_object: ticket.find(123), # optional
    references: ['message-id123', 'message-id456'],
  )

=end

  def self.notification(data)

    # get subject
    result = NotificationFactory.template(
      template: data[:template],
      locale: data[:user].preferences[:locale],
      objects: data[:objects],
    )

    # rebuild subject
    if data[:main_object] && data[:main_object].respond_to?(:subject_build)
      result[:subject] = data[:main_object].subject_build(result[:subject])
    end

    NotificationFactory.send(
      recipient: data[:user],
      subject: result[:subject],
      body: result[:body],
      content_type: 'text/html',
      references: data[:references],
    )
  end

=begin

get count of already sent notifications

  count = NotificationFactory.already_sent?(ticket, recipient_user, type)

retunes

  8

=end

  def self.already_sent?(ticket, recipient, type)
    result = ticket.history_get()
    count  = 0
    result.each {|item|
      next if item['type'] != 'notification'
      next if item['object'] != 'Ticket'
      next if item['value_to'] !~ /#{recipient.email}/i
      next if item['value_to'] !~ /#{type}/i
      count += 1
    }
    count
  end

=begin

  result = NotificationFactory.template(
    template: 'password_reset',
    locale: 'en-us',
    objects:  {
      recipient: User.find(2),
    },
  )

  result = NotificationFactory.template(
    templateInline: "Invitation to <%= c 'product_name' %> at <%= c 'fqdn' %>",
    locale: 'en-us',
    objects:  {
      recipient: User.find(2),
    },
  )

only raw subject/body

  result = NotificationFactory.template(
    template: 'password_reset',
    locale: 'en-us',
    objects:  {
      recipient: User.find(2),
    },
    raw: true,
  )

returns

  {
    subject: 'some sobject',
    body: 'some body',
  }

=end

  def self.template(data)

    if data[:templateInline]
      return NotificationFactory::Template.new(data[:objects], data[:locale], data[:templateInline], false).render
    end

    template_subject = nil
    template_body = ''
    locale = data[:locale] || 'en'
    template = data[:template]
    location = "app/views/mailer/#{template}/#{locale}.html.erb"

    # as fallback, use 2 char locale
    if !File.exist?(location)
      locale = locale[0, 2]
      location = "app/views/mailer/#{template}/#{locale}.html.erb"
    end

    # as fallback, use en
    if !File.exist?(location)
      location = "app/views/mailer/#{template}/en.html.erb"
    end

    File.open(location, 'r:UTF-8').each do |line|
      if !template_subject
        template_subject = line
        next
      end
      template_body += line
    end

    message_subject = NotificationFactory::Template.new(data[:objects], data[:locale], template_subject, false).render
    message_body = NotificationFactory::Template.new(data[:objects], data[:locale], template_body).render

    if !data[:raw]
      application_template = nil
      File.open('app/views/mailer/application.html.erb', 'r:UTF-8') do |file|
        application_template = file.read
      end
      data[:objects][:message] = message_body
      message_body = NotificationFactory::Template.new(data[:objects], data[:locale], application_template).render
    end
    {
      subject: message_subject,
      body: message_body,
    }
  end

  class Template

    def initialize(objects, locale, template, escape = true)
      @objects = objects
      @locale = locale || 'en-us'
      @template = template
      @escape = escape
    end

    def render
      ERB.new(@template).result(binding)
    end

    def d(key, escape = nil)

      # do validaton, ignore some methodes
      if key =~ /(`|\.(|\s*)(save|destroy|delete|remove|drop|update\(|update_att|create\(|new|all|where|find))/i
        return "#{key} (not allowed)"
      end

      value            = nil
      object_methods   = key.split('.')
      object_name      = object_methods.shift.to_sym
      object_refs      = @objects[object_name]
      object_methods_s = ''
      object_methods.each {|method|
        if object_methods_s != ''
          object_methods_s += '.'
        end
        object_methods_s += method

        # if method exists
        if !object_refs.respond_to?( method.to_sym )
          value = "\#{#{object_name}.#{object_methods_s} / no such method}"
          break
        end
        object_refs = object_refs.send( method.to_sym )
      }
      placeholder = if !value
                      object_refs
                    else
                      value
                    end
      return placeholder if escape == false || (escape.nil? && !@escape)
      h placeholder
    end

    def c(key, escape = nil)
      config = Setting.get(key)
      return config if escape == false || (escape.nil? && !@escape)
      h config
    end

    def t(key, escape = nil)
      translation = Translation.translate(@locale, key)
      return translation if escape == false || (escape.nil? && !@escape)
      h translation
    end

    def a(article)
      content_type = d "#{article}.content_type", false
      if content_type =~ /html/
        return d "#{article}.body", false
      end
      d("#{article}.body", false).text2html
    end

    def h(key)
      return key if !key
      CGI.escapeHTML(key.to_s)
    end
  end
end
