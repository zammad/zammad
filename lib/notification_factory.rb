module NotificationFactory
  def self.build(data)

    data[:string].gsub!( / \#\{ \s* ( .+? ) \s* \} /x ) { |placeholder|

      # store possible callback to work with
      # and check if it's valid for execution
      original_string = $&
      callback        = $1
      callback_valid  = nil

      # use quoted text
      callback.gsub!( /\A ( \w+ ) \.body \z/x ) { |item|
        callback_valid = true
        item           = item + '.word_wrap( :line_width => 82 ).message_quote.chomp'
      }

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

        next if !data[:objects][object_name.to_sym]

        callback_valid = true
        item           = "data[:objects]['#{object_name}'.to_sym]#{object_method}"
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

    return data[:string]
  end

  def self.send(data)
    sender = Setting.get('notification_sender')
    imap   = Channel::IMAP.new
    Rails.logger.info "NOTICE: SEND NOTIFICATION TO: #{data[:recipient][:email]}"
    message = imap.send(
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
