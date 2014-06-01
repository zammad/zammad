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
  def to_filename
    camel_cased_word = self.to_s
    camel_cased_word.gsub(/::/, '/').downcase
  end

  # because of mysql inno_db limitations, strip 4 bytes utf8 chars (e. g. emojis)
  # unfortunaly UTF8mb4 will raise other limitaions of max varchar and lower index sizes
  # More details: http://pjambet.github.io/blog/emojis-and-mysql/
  def utf8_to_3bytesutf8
    return if ActiveRecord::Base.connection_config[:adapter] != 'mysql2'
    self.each_char.select {|c|
      if c.bytes.count > 3
        puts "WARNING: strip out 4 bytes utf8 chars '#{c}' of '#{ self }'"
        next
      end
      c
    }
    .join('')
  end
end
