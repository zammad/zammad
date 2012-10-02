class String
  def message_quote
    quote = self.split("\n")
    body_quote = ''
    quote.each do |line|
      body_quote = body_quote + '> ' + line + "\n"
    end
    body_quote
  end
  def word_wrap(*args)
    options = args.extract_options!
    unless args.blank?
      options[:line_width] = args[0] || 82
    end
    options.reverse_merge!(:line_width => 82)

    lines = self
    lines.split("\n").collect do |line|
      line.length > options[:line_width] ? line.gsub(/(.{1,#{options[:line_width]}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
  end
end

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
      s = eval callback
    }
    return data[:string]
  end

  def self.send(data)
    sender = Setting.get('notification_sender')
    a = Channel::IMAP.new
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