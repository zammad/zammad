module NotificationFactory

=begin

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
    recipient:     User.find(123),
    subject:      'sime subject',
    body:         'some body',
    content_type: '', # optional, e. g. 'text/html'
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
        body: data[:body],
        content_type: content_type,
      },
      true
    )
  end
end
