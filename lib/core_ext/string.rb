# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rchardet'

class String
  alias old_strip strip
  alias old_strip! strip!

  def strip!
    begin
      sub!(%r{\A[[[:space:]]\u{200B}\u{FEFF}]+}, '')
      sub!(%r{[[[:space:]]\u{200B}\u{FEFF}]+\Z}, '')

    # if incompatible encoding regexp match (UTF-8 regexp with ASCII-8BIT string) (Encoding::CompatibilityError), use default
    rescue Encoding::CompatibilityError
      old_strip!
    end
    self
  end

  def strip
    begin
      new_string = sub(%r{\A[[[:space:]]\u{200B}\u{FEFF}]+}, '')
      new_string.sub!(%r{[[[:space:]]\u{200B}\u{FEFF}]+\Z}, '')

    # if incompatible encoding regexp match (UTF-8 regexp with ASCII-8BIT string) (Encoding::CompatibilityError), use default
    rescue Encoding::CompatibilityError
      new_string = old_strip
    end
    new_string
  end

  def message_quote
    quote = split("\n")
    body_quote = ''
    quote.each do |line|
      body_quote = "#{body_quote}> #{line}\n"
    end
    body_quote
  end

  def word_wrap(*args)
    options = args.extract_options!
    if args.present?
      options[:line_width] = args[0] || 82
    end
    options.reverse_merge!(line_width: 82)

    lines = self
    lines.split("\n").collect do |line|
      line.length > options[:line_width] ? line.gsub(%r{(.{1,#{options[:line_width]}})(\s+|$)}, "\\1\n").strip : line
    end * "\n"
  end

=begin

  filename = 'Some::Module'.to_filename

  returns
    'some/module'

=end

  def to_filename
    camel_cased_word = dup
    camel_cased_word.gsub(%r{::}, '/')
                    .gsub(%r{([A-Z]+)([A-Z][a-z])}, '\1_\2')
                    .gsub(%r{([a-z\d])([A-Z])}, '\1_\2')
                    .tr('-', '_').downcase
  end

=begin

  filename = 'some/module.rb'.to_classname

  returns
    'Some::Module'

=end

  def to_classname
    camel_cased_word = dup
    camel_cased_word.delete_suffix!('.rb')
    camel_cased_word.split('/').map(&:camelize).join('::')
  end

  # because of mysql inno_db limitations, strip 4 bytes utf8 chars (e. g. emojis)
  # unfortunaly UTF8mb4 will raise other limitaions of max varchar and lower index sizes
  # More details: http://pjambet.github.io/blog/emojis-and-mysql/
  def utf8_to_3bytesutf8
    return self if Rails.application.config.db_4bytes_utf8

    each_char.select do |c|
      if c.bytes.count > 3
        Rails.logger.warn "strip out 4 bytes utf8 chars '#{c}' of '#{self}'"
        next
      end
      c
    end
             .join
  end

=begin

  text = html_string.html2text

  returns

    'string with text only'

=end

  def html2text(string_only = false, strict = false)
    string = dup

    # in case of invalid encoding, strip invalid chars
    # see also test/data/mail/mail021.box
    # note: string.encode!('UTF-8', 'UTF-8', :invalid => :replace, :replace => '?') was not detecting invalid chars
    if !string.valid_encoding?
      string = string.chars.select(&:valid_encoding?).join
    end

    # remove html comments
    string.gsub!(%r{<!--.+?-->}m, '')

    # find <a href=....> and replace it with [x]
    link_list = ''
    counter   = 0
    if string_only
      string.gsub!(%r{<a[[:space:]]+(|\S+[[:space:]]+)href=("|')(.+?)("|')([[:space:]]*|[[:space:]]+[^>]*)>(.+?)<[[:space:]]*/a[[:space:]]*>}mxi) do |_placeholder|
        link = $3
        text = $6
        text.gsub!(%r{<.+?>}, '')

        link_compare = link.dup
        if link_compare.present?
          link.strip!
          link_compare.strip!
          link_compare.downcase!
          link_compare.sub!(%r{/$}, '')
        end
        text_compare = text.dup
        if text_compare.present?
          text.strip!
          text_compare.strip!
          text_compare.downcase!
          text_compare.sub!(%r{/$}, '')
        end

        if link_compare.present? && text_compare.blank?
          link
        elsif (link_compare.blank? && text_compare.present?) || (link_compare && link_compare =~ %r{^mailto}i)
          text
        elsif link_compare.present? && text_compare.present? && (link_compare == text_compare || link_compare == "mailto:#{text}".downcase || link_compare == "http://#{text}".downcase)
          "######LINKEXT:#{link}/TEXT:#{text}######"
        elsif text !~ %r{^http}
          "#{text} (######LINKRAW:#{link}######)"
        else
          "#{link} (######LINKRAW:#{text}######)"
        end
      end
    elsif string.scan(%r{<a[[:space:]]}i).count < 5_000
      string.gsub!(%r{<a[[:space:]].*?href=("|')(.+?)("|').*?>}ix) do
        link = $2
        counter = counter + 1
        link_list += "[#{counter}] #{link}\n"
        "[#{counter}] "
      end
    end

    # remove style tags with content
    string.gsub!(%r{<style(|[[:space:]].+?)>(.+?)</style>}im, '')

    # remove empty lines
    string.gsub!(%r{^[[:space:]]*}m, '')
    if strict
      string.gsub!(%r{< [[:space:]]* (/*) [[:space:]]* (b|i|ul|ol|li|u|h1|h2|h3|hr) ([[:space:]]*|[[:space:]]+[^>]*) >}mxi, '######\1\2######')
    end

    # pre/code handling 1/2
    string.gsub!(%r{<pre>(.+?)</pre>}m) do |placeholder|
      placeholder.gsub(%r{\n}, '###BR###')
    end
    string.gsub!(%r{<code>(.+?)</code>}m) do |placeholder|
      placeholder.gsub(%r{\n}, '###BR###')
    end

    # insert spaces on [A-z]\n[A-z]
    string.gsub!(%r{([A-z])[[:space:]]([A-z])}m, '\1 \2')

    # remove all new lines
    string.gsub!(%r{(\n\r|\r\r\n|\r\n|\n)}, '')

    # blockquote handling
    string.gsub!(%r{<blockquote(| [^>]*)>(.+?)</blockquote>}m) do
      "\n#{$2.html2text(true).gsub(%r{^(.*)$}, '&gt; \1')}\n"
    end

    # pre/code handling 2/2
    string.gsub!(%r{###BR###}, "\n")

    # add counting
    string.gsub!(%r{<li(| [^>]*)>}i, "\n* ")

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
    string.gsub!(%r{<.+?>}, '')

    # replace multiple spaces with one
    string.gsub!(%r{  }, ' ')

    # add hyperlinks
    if strict
      string.gsub!(%r{([[:space:]])((http|https|ftp|tel)://.+?|(www..+?))([[:space:]]|\.[[:space:]]|,[[:space:]])}mxi) do |_placeholder|
        pre = $1
        content = $2
        post = $5
        if content.match?(%r{^www}i)
          content = "http://#{content}"
        end

        if content =~ %r{^(http|https|ftp|tel)}i
          "#{pre}######LINKRAW:#{content}#######{post}"
        else
          "#{pre}#{content}#{post}"
        end
      end
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
      string.gsub!(%r{(&\#(\d+);?)}x) do
        $2.chr
      end

      # encode html entities like "&#3d;"
      string.gsub!(%r{(&\#[xX]([0-9a-fA-F]+);?)}x) do
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
      end
    end
    string = string.utf8_encode(fallback: :read_as_sanitized_binary)

    # remove tailing empty spaces
    string.gsub!(%r{[[:blank:]]+$}, '')

    # remove double multiple empty lines
    string.gsub!(%r{\n\n\n+}, "\n\n")

    # add extracted links
    if link_list != ''
      string += "\n\n\n#{link_list}"
    end

    # remove double multiple empty lines
    string.gsub!(%r{\n\n\n+}, "\n\n")

    string.strip
  end

=begin

  html = text_string.text2html

=end

  def text2html
    text = CGI.escapeHTML(self)
    text.gsub!(%r{\n}, '<br>')
    text.chomp
  end

=begin

  html = text_string.text2html

=end

  def html2html_strict
    string = dup
    string = HtmlSanitizer.strict(string, true).strip
    string = HtmlSanitizer.cleanup(string).strip

    # as fallback, use html2text and text2html
    if string.blank?
      string = html2text.text2html
      string.signature_identify('text')
      marker_template = '<span class="js-signatureMarker"></span>'
      string.sub!(%r{######SIGNATURE_MARKER######}, marker_template)
      string.gsub!(%r{######SIGNATURE_MARKER######}, '')
      return string.chomp
    end
    string.gsub!(%r{(<p>[[:space:]]*</p>([[:space:]]*)){2,}}im, '<p>&nbsp;</p>\2')
    string.gsub!(%r\<div>[[:space:]]*(<br(|/)>([[:space:]]*)){2,}\im, '<div><br>\3')
    string.gsub!(%r\[[:space:]]*(<br>[[:space:]]*){3,}[[:space:]]*</div>\im, '<br><br></div>')
    string.gsub!(%r\<div>[[:space:]]*(<br>[[:space:]]*){1,}[[:space:]]*</div>\im, '<div>&nbsp;</div>')
    string.gsub!(%r\<div>[[:space:]]*(<div>[[:space:]]*</div>[[:space:]]*){2,}</div>\im, '<div>&nbsp;</div>')
    string.gsub!(%r\<p>[[:space:]]*</p>(<br(|/)>[[:space:]]*){2,}[[:space:]]*\im, '<p> </p><br>')
    string.gsub!(%r{<p>[[:space:]]*</p>(<br(|/)>[[:space:]]*)+<p>[[:space:]]*</p>}im, '<p> </p><p> </p>')
    string.gsub!(%r\(<div>[[:space:]]*</div>[[:space:]]*){2,}\im, '<div> </div>')
    string.gsub!(%r{<div>&nbsp;</div>[[:space:]]*(<div>&nbsp;</div>){1,}}im, '<div>&nbsp;</div>')
    string.gsub!(%r{(<br>[[:space:]]*){3,}}im, '<br><br>')
    string.gsub!(%r\(<br(|/)>[[:space:]]*){3,}\im, '<br/><br/>')
    string.gsub!(%r{<p>[[:space:]]+</p>}im, '<p>&nbsp;</p>')
    string.gsub!(%r{\A(<br(|/)>[[:space:]]*)*}i, '')
    string.gsub!(%r{[[:space:]]*(<br(|/)>[[:space:]]*)*\Z}i, '')
    string.gsub!(%r{(<p></p>){1,10}\Z}i, '')

    string.signature_identify('html')

    marker_template = '<span class="js-signatureMarker"></span>'
    string.sub!(%r{######SIGNATURE_MARKER######}, marker_template)
    string.gsub!(%r{######SIGNATURE_MARKER######}, '')
    string.chomp
  end

  def signature_identify(type = 'text', force = false)
    string = self

    marker = '######SIGNATURE_MARKER######'

    if type == 'html'
      map = [
        '<br(|\/)>[[:space:]]*(--|__)',
        '<\/div>[[:space:]]*(--|__)',
        '<p>[[:space:]]*(--|__)',
        '(<br(|\/)>|<p>|<div>)[[:space:]]*<b>(|<span[[:space:]]lang=".{1,6}">)(Von|From|De|от|Z|Od|Ze|Fra|Van|Mistä|Από|Dal|から|Из|од|iz|Från|จาก|з|Từ):[[:space:]]*(|</span>)</b>',
        '(<br>|<div>)[[:space:]]*<br>[[:space:]]*(Von|From|De|от|Z|Od|Ze|Fra|Van|Mistä|Από|Dal|から|Из|од|iz|Från|จาก|з|Từ):[[:space:]]+',
        '<blockquote(|.+?)>[[:space:]]*<div>[[:space:]]*(On|Am|Le|El|Den|Dňa|W dniu|Il|Op|Dne|Dana)[[:space:]]',
        '<div(|.+?)>[[:space:]]*<br>[[:space:]]*(On|Am|Le|El|Den|Dňa|W dniu|Il|Op|Dne|Dana)[[:space:]].{1,500}<blockquote',
      ]
      map.each do |regexp|
        string.sub!(%r{#{regexp}}m) do |placeholder|
          "#{marker}#{placeholder}"
        end
      end
      return string
    end

    # if we do have less then 10 lines and less then 300 chars ignore this
    if !force
      lines = string.split("\n")
      return if lines.count < 10 && string.length < 300
    end

    # search for signature separator "--\n"
    string.sub!(%r{^\s{0,2}--\s{0,2}$}) do |placeholder|
      "#{marker}#{placeholder}"
    end

    map = {}
    # Apple Mail
    # On 01/04/15 10:55, Bob Smith wrote:
    map['apple-en'] = '^(On)[[:space:]].{6,20}[[:space:]].{3,10}[[:space:]].{1,250}[[:space:]](wrote):'

    # Am 03.04.2015 um 20:58 schrieb Martin Edenhofer <me@znuny.ink>:
    map['apple-de'] = '^(Am)[[:space:]].{6,20}[[:space:]](um)[[:space:]].{3,10}[[:space:]](schrieb)[[:space:]].{1,250}:'

    # Thunderbird
    # Am 04.03.2015 um 12:47 schrieb Alf Aardvark:
    map['thunderbird-de'] = '^(Am)[[:space:]].{6,20}[[:space:]](um)[[:space:]].{3,10}[[:space:]](schrieb)[[:space:]].{1,250}:'

    # Thunderbird default - http://kb.mozillazine.org/Reply_header_settings
    # On 01-01-2007 11:00 AM, Alf Aardvark wrote:
    map['thunderbird-en-default'] = '^(On)[[:space:]].{6,20}[[:space:]].{3,10},[[:space:]].{1,250}(wrote):'

    # http://kb.mozillazine.org/Reply_header_settings
    # Alf Aardvark wrote, on 01-01-2007 11:00 AM:
    map['thunderbird-en'] = '^.{1,250}[[:space:]](wrote),[[:space:]]on[[:space:]].{3,20}:'

    # otrs
    # 25.02.2015 10:26 - edv hotline wrote:
    # 25.02.2015 10:26 - edv hotline schrieb:
    map['otrs-en-de'] = '^.{6,10}[[:space:]].{3,10}[[:space:]]-[[:space:]].{1,250}[[:space:]](wrote|schrieb):'

    # Ms
    # rubocop:disable Style/AsciiComments
    # From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]
    # Send: Donnerstag, 2. April 2015 10:00
    # To/Cc/Bcc: xxx
    # Subject: xxx
    # - or -
    # From: xxx
    # To/Cc/Bcc: xxx
    # Date: 01.04.2015 12:41
    # Subject: xxx
    # - or -
    # De : xxx
    # À/?/?: xxx
    # Envoyé : mercredi 29 avril 2015 17:31
    # Objet : xxx
    # rubocop:enable Style/AsciiComments

    # en/de/fr | sometimes ms adds a space to "xx : value"
    map['ms-en-de-fr_from'] = '^(Von|From|De|от|Z|Od|Ze|Fra|Van|Mistä|Από|Dal|から|Из|од|iz|Från|จาก|з|Từ)( ?):[[:space:]].+?'
    map['ms-en-de-fr_from_html'] = "\n######b######(From|Von|De)([[:space:]]?):([[:space:]]?)(######\/b######)[[:space:]].+?"

    # word 14
    # edv hotline wrote:
    # edv hotline schrieb:
    #map['word-en-de'] = "[^#{marker}].{1,250}\s(wrote|schrieb):"

    map.each_value do |regexp|
      string.sub!(%r{#{regexp}}) do |placeholder|
        "#{marker}#{placeholder}"
      rescue
        # regexp was not possible because of some string encoding issue, use next
        Rails.logger.debug { "Invalid string/charset combination with regexp #{regexp} in string" }
      end
    end

    string
  end

  # Returns a copied string whose encoding is UTF-8.
  # If both the provided and current encodings are invalid,
  # an auto-detected encoding is tried.
  #
  # Supports some fallback strategies if a valid encoding cannot be found.
  #
  # Options:
  #
  #   * from: An encoding to try first.
  #           Takes precedence over the current and auto-detected encodings.
  #
  #   * fallback: The strategy to follow if no valid encoding can be found.
  #     * `:output_to_binary` returns an ASCII-8BIT-encoded string.
  #     * `:read_as_sanitized_binary` returns a UTF-8-encoded string with all
  #       invalid byte sequences replaced with "?" characters.
  def utf8_encode(**options)
    dup.utf8_encode!(options)
  end

  def utf8_encode!(**options)
    return force_encoding('utf-8') if dup.force_encoding('utf-8').valid_encoding?

    # convert string to given charset, if valid_encoding? is true
    if options[:from].present?
      begin
        encoding = Encoding.find(options[:from])
        if encoding.present? && dup.force_encoding(encoding).valid_encoding?
          force_encoding(encoding)
          return encode!('utf-8', encoding)
        end
      rescue ArgumentError, EncodingError => e
        Rails.logger.error { e.inspect }
      end
    end

    # try to find valid encodings of string
    viable_encodings.each do |enc|

      return encode!('utf-8', enc)
    rescue EncodingError => e
      Rails.logger.error { e.inspect }

    end

    case options[:fallback]
    when :output_to_binary
      force_encoding('ascii-8bit')
    when :read_as_sanitized_binary
      encode!('utf-8', 'ascii-8bit', invalid: :replace, undef: :replace, replace: '?')
    else
      raise EncodingError, 'could not find a valid input encoding'
    end
  end

  private

  def viable_encodings(try_first: nil)
    return dup.viable_encodings(try_first: try_first) if frozen?

    provided = Encoding.find(try_first) if try_first.present?
    original = encoding
    detected = CharDet.detect(self)['encoding']

    [provided, original, detected]
      .compact
      .reject { |e| Encoding.find(e) == Encoding::ASCII_8BIT }
      .reject { |e| Encoding.find(e) == Encoding::UTF_8 }
      .select { |e| force_encoding(e).valid_encoding? }
      .tap { force_encoding(original) } # clean up changes from previous line

  # if `try_first` is not a valid encoding, try_first again without it
  rescue ArgumentError
    try_first.present? ? viable_encodings : raise
  end
end
