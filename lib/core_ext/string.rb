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
