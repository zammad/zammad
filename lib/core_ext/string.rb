class String
  def message_quote
    quote = split("\n")
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
    options.reverse_merge!(line_width: 82)

    lines = self
    lines.split("\n").collect do |line|
      line.length > options[:line_width] ? line.gsub(/(.{1,#{options[:line_width]}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
  end

=begin

  filename = 'Some::Module'.to_filename

  returns
    'some/module'

=end

  def to_filename
    camel_cased_word = "#{self}" # rubocop:disable Style/UnneededInterpolation
    camel_cased_word.gsub(/::/, '/')
                    .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                    .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                    .tr('-', '_').downcase
  end

=begin

  filename = 'some/module.rb'.to_classname

  returns
    'Some::Module'

=end

  def to_classname
    camel_cased_word = "#{self}" # rubocop:disable Style/UnneededInterpolation
    camel_cased_word.gsub!(/\.rb$/, '')
    camel_cased_word.split('/').map(&:camelize).join('::')
  end

  # because of mysql inno_db limitations, strip 4 bytes utf8 chars (e. g. emojis)
  # unfortunaly UTF8mb4 will raise other limitaions of max varchar and lower index sizes
  # More details: http://pjambet.github.io/blog/emojis-and-mysql/
  def utf8_to_3bytesutf8
    return self if Rails.application.config.db_4bytes_utf8
    each_char.select {|c|
      if c.bytes.count > 3
        Rails.logger.warn "strip out 4 bytes utf8 chars '#{c}' of '#{self}'"
        next
      end
      c
    }
             .join('')
  end

=begin

  text = html_string.html2text

  returns

    'string with text only'

=end

  def html2text(string_only = false, strict = false)
    string = "#{self}" # rubocop:disable Style/UnneededInterpolation

    # in case of invalid encodeing, strip invalid chars
    # see also test/fixtures/mail21.box
    # note: string.encode!('UTF-8', 'UTF-8', :invalid => :replace, :replace => '?') was not detecting invalid chars
    if !string.valid_encoding?
      string = string.chars.select(&:valid_encoding?).join
    end

    # find <a href=....> and replace it with [x]
    link_list = ''
    counter   = 0
    if !string_only
      string.gsub!(/<a\s.*?href=("|')(.+?)("|').*?>/ix) {
        link = $2
        counter = counter + 1
        link_list += "[#{counter}] #{link}\n"
        "[#{counter}] "
      }
    else
      string.gsub!(%r{<a\s+href=("|')(.+?)("|')(\s*|\s+[^>]*)>(.+?)<\s*/a\s*>}mxi) {|_placeholder|
        link = $2
        if !link.empty?
          link.strip!
        end
        text = $5
        if !text.empty?
          text.strip!
        end
        placeholder = if !link.empty? && text.empty?
                        link
                      elsif link.empty? && !text.empty?
                        text
                      elsif !link.empty? && !text.empty? && (link.downcase == text.downcase || link.downcase == "mailto:#{text}".downcase || link.downcase == "http://#{text}".downcase)
                        text
                      else
                        "#{text} (#{link})"
                      end
      }
    end

    # remove style tags with content
    string.gsub!(%r{<style(|\s.+?)>(.+?)</style>}im, '')

    # remove empty lines
    string.gsub!(/^[[:space:]]*/m, '')
    if strict
      string.gsub!(%r{< \s* (/*) \s* (b|i|ul|ol|li|u|h1|h2|h3|hr) (\s*|\s+[^>]*) >}mxi, '######\1\2######')
    end

    # pre/code handling 1/2
    string.gsub!(%r{<pre>(.+?)</pre>}m) { |placeholder|
      placeholder = placeholder.gsub(/\n/, '###BR###')
    }
    string.gsub!(%r{<code>(.+?)</code>}m) { |placeholder|
      placeholder = placeholder.gsub(/\n/, '###BR###')
    }

    # insert spaces on [A-z]\n[A-z]
    string.gsub!(/([A-z])[[:space:]]([A-z])/m, '\1 \2')

    # remove all new lines
    string.gsub!(/(\n\r|\r\r\n|\r\n|\n)/, '')

    # blockquote handling
    string.gsub!(%r{<blockquote(| [^>]*)>(.+?)</blockquote>}m) {
      "\n" + $2.html2text(true).gsub(/^(.*)$/, '&gt; \1') + "\n"
    }

    # pre/code handling 2/2
    string.gsub!(/###BR###/, "\n")

    # add counting
    string.gsub!(/<li(| [^>]*)>/i, "\n* ")

    # add hr
    string.gsub!(%r{<hr(|/| [^>]*)>}i, "\n___\n")

    # add h\d
    string.gsub!(%r{</h\d>}i, "\n")

    # add new lines
    string.gsub!(%r{</div><div(|\s.+?)>}im, "\n")
    string.gsub!(%r{</p><p(|\s.+?)>}im, "\n")
    string.gsub!(%r{<(div|p|pre|br|table|tr|h)(|/| [^>]*)>}i, "\n")
    string.gsub!(%r{</(p|br|div)(|\s.+?)>}i, "\n")
    string.gsub!(%r{</td>}i, ' ')

    # strip all other tags
    string.gsub!(/\<.+?\>/, '')

    # replace multiple spaces with one
    string.gsub!(/  /, ' ')

    # try HTMLEntities, if it fails on invalid signes, use manual way
    begin
      coder = HTMLEntities.new
      string = coder.decode(string)
    rescue

      # strip all &amp; &lt; &gt; &quot;
      string.gsub!('&amp;', '&')
      string.gsub!('&lt;', '<')
      string.gsub!('&gt;', '>')
      string.gsub!('&quot;', '"')
      string.gsub!('&nbsp;', ' ')

      # encode html entities like "&#8211;"
      string.gsub!(/(&\#(\d+);?)/x) {
        $2.chr
      }

      # encode html entities like "&#3d;"
      string.gsub!(/(&\#[xX]([0-9a-fA-F]+);?)/x) {
        chr_orig = $1
        hex      = $2.hex
        if hex
          chr = hex.chr
          if chr
            chr_orig = chr
          else
            chr_orig
          end
        else
          chr_orig
        end

        # check valid encoding
        begin
          if !chr_orig.encode('UTF-8').valid_encoding?
            chr_orig = '?'
          end
        rescue
          chr_orig = '?'
        end
        chr_orig
      }
    end

    # remove tailing empty spaces
    string.gsub!(/[[:blank:]]+$/, '')

    # remove double multiple empty lines
    string.gsub!(/\n\n\n/, "\n\n")

    # add extracted links
    if link_list != ''
      string += "\n\n\n" + link_list
    end

    # remove double multiple empty lines
    string.gsub!(/\n\n\n/, "\n\n")

    string.strip
  end

=begin

  html = text_string.text2html

=end

  def text2html
    text = CGI.escapeHTML(self)
    text.gsub!(/\n/, '<br>')
    text.chomp
  end

=begin

  html = text_string.text2html

=end

  def html2html_strict
    string = html2text(true, true)
    string = string.text2html
    string.gsub!(/######(.+?)######/, '<\1>')
    string.chomp
  end

end
