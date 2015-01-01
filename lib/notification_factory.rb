module NotificationFactory

=begin

  result_string = NotificationFactory.build(
    :string  => 'Hi #{recipient.firstname},',
    :objects => {
      :ticket    => ticket,
      :recipient => User.find(2),
    },
    :locale  => 'en',
  )

=end

  def self.build(data)

    data[:string].gsub!( / \#\{ \s* ( .+? ) \s* \} /x ) { |placeholder|

      # store possible callback to work with
      # and check if it's valid for execution
      original_string = $&
      callback        = $1
      callback_valid  = nil

      # use config params
      callback.gsub!( /\A config\.( [\w\.]+ ) \z/x ) { |item|
        callback_valid = true
        name           = $1
        item           = "Setting.get('#{name}')"
      }

      # use object params
      callback.gsub!( /\A ( [\w]+ )( \.[\w\.]+ ) \z/x ) { |item|

        object_name   = $1
        object_method = $2

        if data[:objects][object_name.to_sym]
          callback_valid = true
          item           = "data[:objects]['#{object_name}'.to_sym]#{object_method}"
        else
          item = item
        end
      }

      # use quoted text
      callback.gsub!( /\A ( data\[:objects\]\['article'\.to_sym\] ) \.body \z/x ) { |item|
        callback_valid = true
        if data[:objects][:article].content_type == 'text/html'
          item           = item + '.html2text.message_quote.chomp'
        else
          item           = item + '.word_wrap( :line_width => 82 ).message_quote.chomp'
        end
      }

      # do validaton, ignore some methodes
      callback.gsub!( /\.(save|destroy|delete|remove|drop|update|create\(|new|all|where|find)/ix ) { |item|
        callback_valid = false
      }

      if callback_valid
        # replace value
        begin
          placeholder = eval callback
        rescue Exception => e
          Rails.logger.error "Evaluation error caused by callback '#{callback}'"
          Rails.logger.error e.inspect
        end
      else
        placeholder = original_string
      end
    }

    # translate
    data[:string].gsub!( /i18n\((.+?)\)/ ) { |placeholder|
      string      = $1
      locale      = data[:locale] || 'en'
      placeholder = Translation.translate( locale, string )
    }

    data[:string]
  end

=begin

  success = NotificationFactory.send(
    :to      => 'somebody@example.com',
    :subject => 'sime subject',
    :body    => 'some body'
  )

=end

  def self.send(data)
    sender = Setting.get('notification_sender')
    Rails.logger.info "NOTICE: SEND NOTIFICATION TO: #{data[:recipient][:email]} (from #{sender})"

    Channel::EmailSend.send(
      {
#        :in_reply_to => self.in_reply_to,
        :from       => sender,
        :to         => data[:recipient][:email],
        :subject    => data[:subject],
        :body       => data[:body],
      },
      true
    )
  end
end