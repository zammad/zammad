module NotificationFactory
  def self.build(data)

    data[:string].gsub!( /\#\{(.+?)\}/ ) { |s|

      # use quoted text
      callback = $1
      callback.gsub!( /\.body$/ ) { |item|
        item = item + '.word_wrap( :line_width => 82 ).message_quote.chomp'
      }

      # use config params
      callback.gsub!( /^config\.(.+?)$/ ) { |item|
        name = $1
        item = "Setting.get('#{$1}')"
      }

      # use object params
      callback.gsub!( /^(.+?)(\..+?)$/ ) { |item|
        object_name   = $1
        object_method = $2
        replace = nil
        if data[:objects][object_name.to_sym]
          replace = "data[:objects]['#{object_name}'.to_sym]#{object_method}"
        else
          replace = $1 + $2
        end
        item = replace
      }

      # replace value
      begin
        s = eval callback
      rescue Exception => e
        Rails.logger.error "can't eval #{callback}"
        Rails.logger.error e.inspect
      end
    }

    # translate
    data[:string].gsub!( /i18n\((.+?)\)/ ) { |s|
      string = $1
      locale = data[:locale] || 'en'
      s = Translation.translate( locale, string )
    }

    return data[:string]
  end

  def self.send(data)
    sender = Setting.get('notification_sender')
    a = Channel::IMAP.new
    Rails.logger.info "NOTICE: SEND NOTIFICATION TO: #{data[:recipient][:email]}"
    message = a.send(
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
