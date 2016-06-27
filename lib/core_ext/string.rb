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

    # remove html comments
    string.gsub!(/<!--.+?-->/m, '')

    # find <a href=....> and replace it with [x]
    link_list = ''
    counter   = 0
    if !string_only
      string.gsub!(/<a[[:space:]].*?href=("|')(.+?)("|').*?>/ix) {
        link = $2
        counter = counter + 1
        link_list += "[#{counter}] #{link}\n"
        "[#{counter}] "
      }
    else
      string.gsub!(%r{<a[[:space:]]+(|\S+[[:space:]]+)href=("|')(.+?)("|')([[:space:]]*|[[:space:]]+[^>]*)>(.+?)<[[:space:]]*/a[[:space:]]*>}mxi) {|_placeholder|
        link = $3
        text = $6
        text.gsub!(/\<.+?\>/, '')

        link_compare = link.dup
        if !link_compare.empty?
          link.strip!
          link_compare.strip!
          link_compare.downcase!
          link_compare.sub!(%r{/$}, '')
        end
        text_compare = text.dup
        if !text_compare.empty?
          text.strip!
          text_compare.strip!
          text_compare.downcase!
          text_compare.sub!(%r{/$}, '')
        end
        placeholder = if !link_compare.empty? && text_compare.empty?
                        link
                      elsif link_compare.empty? && !text_compare.empty?
                        text
                      elsif link_compare && link_compare =~ /^mailto/i
                        text
                      elsif !link_compare.empty? && !text_compare.empty? && (link_compare == text_compare || link_compare == "mailto:#{text}".downcase || link_compare == "http://#{text}".downcase)
                        "######LINKEXT:#{link}/TEXT:#{text}######"
                      elsif text !~ /^http/
                        "#{text} (######LINKRAW:#{link}######)"
                      else
                        "#{link} (######LINKRAW:#{text}######)"
                      end
      }
    end

    # remove style tags with content
    string.gsub!(%r{<style(|[[:space:]].+?)>(.+?)</style>}im, '')

    # remove empty lines
    string.gsub!(/^[[:space:]]*/m, '')
    if strict
      string.gsub!(%r{< [[:space:]]* (/*) [[:space:]]* (b|i|ul|ol|li|u|h1|h2|h3|hr) ([[:space:]]*|[[:space:]]+[^>]*) >}mxi, '######\1\2######')
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
    string.gsub!(%r{</div><div(|[[:space:]].+?)>}im, "\n")
    string.gsub!(%r{</p><p(|[[:space:]].+?)>}im, "\n")
    string.gsub!(%r{<(div|p|pre|br|table|tr|h)(|/| [^>]*)>}i, "\n")
    string.gsub!(%r{</(p|br|div)(|[[:space:]].+?)>}i, "\n")
    string.gsub!(%r{</td>}i, ' ')

    # strip all other tags
    string.gsub!(/\<.+?\>/, '')

    # replace multiple spaces with one
    string.gsub!(/  /, ' ')

    # add hyperlinks
    if strict
      string.gsub!(%r{([[:space:]])((http|https|ftp|tel)://.+?|(www..+?))([[:space:]]|\.[[:space:]]|,[[:space:]])}mxi) {|_placeholder|
        pre = $1
        content = $2
        post = $5
        if content =~ /^www/i
          content = "http://#{content}"
        end
        placeholder = if content =~ /^(http|https|ftp|tel)/i
                        "#{pre}######LINKRAW:#{content}#######{post}"
                      else
                        "#{pre}#{content}#{post}"
                      end
      }
    end

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
    string.gsub!(/\n\n\n+/, "\n\n")

    # add extracted links
    if link_list != ''
      string += "\n\n\n" + link_list
    end

    # remove double multiple empty lines
    string.gsub!(/\n\n\n+/, "\n\n")

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
    string.gsub!(%r{######LINKEXT:(.+?)/TEXT:(.+?)######}, '<a href="\1" target="_blank">\2</a>')
    string.gsub!(/######LINKRAW:(.+?)######/, '<a href="\1" target="_blank">\1</a>')
    string.gsub!(/######(.+?)######/, '<\1>')
    string.chomp
  end

end
