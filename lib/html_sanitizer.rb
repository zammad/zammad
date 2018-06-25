class HtmlSanitizer

=begin

satinize html string based on whiltelist

  string = HtmlSanitizer.strict(string, external)

=end

  def self.strict(string, external = false)

    # config
    tags_remove_content = Rails.configuration.html_sanitizer_tags_remove_content
    tags_quote_content = Rails.configuration.html_sanitizer_tags_quote_content
    tags_whitelist = Rails.configuration.html_sanitizer_tags_whitelist
    attributes_whitelist = Rails.configuration.html_sanitizer_attributes_whitelist
    css_properties_whitelist = Rails.configuration.html_sanitizer_css_properties_whitelist
    css_values_blacklist = Rails.application.config.html_sanitizer_css_values_backlist
    classes_whitelist = ['js-signatureMarker']
    attributes_2_css = %w[width height]

    # remove html comments
    string.gsub!(/<!--.+?-->/m, '')

    scrubber_link = Loofah::Scrubber.new do |node|

      # check if text has urls which need to be clickable
      if node&.name != 'a' && node.parent && node.parent.name != 'a' && (!node.parent.parent || node.parent.parent.name != 'a')
        if node.class == Nokogiri::XML::Text
          urls = []
          node.content.scan(%r{((http|https|ftp|tel)://.+?)([[:space:]]|\.[[:space:]]|,[[:space:]]|\.$|,$|\)|\(|$)}mxi).each do |match|
            if match[0]
              urls.push match[0].to_s.strip
            end
          end
          node.content.scan(/(^|:|;|\s)(www\..+?)([[:space:]]|\.[[:space:]]|,[[:space:]]|\.$|,$|\)|\(|$)/mxi).each do |match|
            if match[1]
              urls.push match[1].to_s.strip
            end
          end
          next if urls.blank?
          add_link(node.content, urls, node)
        end
      end

      # prepare links
      if node['href']
        href                = cleanup_target(node['href'], keep_spaces: true)
        href_without_spaces = href.gsub(/[[:space:]]/, '')
        if external && href_without_spaces.present? && !href_without_spaces.downcase.start_with?('//') && href_without_spaces.downcase !~ %r{^.{1,6}://.+?}
          node['href']        = "http://#{node['href']}"
          href                = node['href']
          href_without_spaces = href.gsub(/[[:space:]]/, '')
        end

        next if !href_without_spaces.downcase.start_with?('http', 'ftp', '//')
        node.set_attribute('href', href)
        node.set_attribute('rel', 'nofollow noreferrer noopener')
        node.set_attribute('target', '_blank')
      end

      if node.name == 'a' && node['href'].blank?
        node.replace node.children.to_s
        Loofah::Scrubber::STOP
      end

      # check if href is different to text
      if node.name == 'a' && !url_same?(node['href'], node.text)
        if node['title'].blank?
          node['title'] = node['href']
        end
      end
    end

    scrubber_wipe = Loofah::Scrubber.new do |node|

      # remove tags with subtree
      if tags_remove_content.include?(node.name)
        node.remove
        Loofah::Scrubber::STOP
      end

      # remove tag, insert quoted content
      if tags_quote_content.include?(node.name)
        string = html_decode(node.content)
        text = Nokogiri::XML::Text.new(string, node.document)
        node.add_next_sibling(text)
        node.remove
        Loofah::Scrubber::STOP
      end

      # replace tags, keep subtree
      if !tags_whitelist.include?(node.name)
        node.replace node.children.to_s
        Loofah::Scrubber::STOP
      end

      # prepare src attribute
      if node['src']
        src = cleanup_target(node['src'])
        if src =~ /(javascript|livescript|vbscript):/i || src.downcase.start_with?('http', 'ftp', '//')
          node.remove
          Loofah::Scrubber::STOP
        end
      end

      # clean class / only use allowed classes
      if node['class']
        classes = node['class'].gsub(/\t|\n|\r/, '').split(' ')
        class_new = ''
        classes.each do |local_class|
          next if !classes_whitelist.include?(local_class.to_s.strip)
          if class_new != ''
            class_new += ' '
          end
          class_new += local_class
        end
        if class_new != ''
          node['class'] = class_new
        else
          node.delete('class')
        end
      end

      # move style attributes to css attributes
      attributes_2_css.each do |key|
        next if !node[key]
        if node['style'].blank?
          node['style'] = ''
        else
          node['style'] += ';'
        end
        value = node[key]
        node.delete(key)
        next if value.blank?
        value += 'px' if !value.match?(/%|px|em/i)
        node['style'] += "#{key}:#{value}"
      end

      # clean style / only use allowed style properties
      if node['style']
        pears = node['style'].downcase.gsub(/\t|\n|\r/, '').split(';')
        style = ''
        pears.each do |local_pear|
          prop = local_pear.split(':')
          next if !prop[0]
          key = prop[0].strip
          next if !css_properties_whitelist.include?(node.name)
          next if !css_properties_whitelist[node.name].include?(key)
          next if css_values_blacklist[node.name]&.include?(local_pear.gsub(/[[:space:]]/, '').strip)
          style += "#{local_pear};"
        end
        node['style'] = style
        if style == ''
          node.delete('style')
        end
      end

      # scan for invalid link content
      %w[href style].each do |attribute_name|
        next if !node[attribute_name]
        href = cleanup_target(node[attribute_name])
        next if href !~ /(javascript|livescript|vbscript):/i
        node.delete(attribute_name)
      end

      # remove attributes if not whitelisted
      node.each do |attribute, _value|
        attribute_name = attribute.downcase
        next if attributes_whitelist[:all].include?(attribute_name) || (attributes_whitelist[node.name]&.include?(attribute_name))
        node.delete(attribute)
      end

      # remove mailto links
      if node['href']
        href = cleanup_target(node['href'])
        if href =~ /mailto:(.*)$/i
          text = Nokogiri::XML::Text.new($1, node.document)
          node.add_next_sibling(text)
          node.remove
          Loofah::Scrubber::STOP
        end
      end
    end

    new_string = ''
    done = true
    while done
      new_string = Loofah.fragment(string).scrub!(scrubber_wipe).to_s
      if string == new_string
        done = false
      end
      string = new_string
    end

    Loofah.fragment(string).scrub!(scrubber_link).to_s
  end

=begin

cleanup html string:

 * remove empty nodes (p, div, span, table)
 * remove nodes in general (keep content - span)

  string = HtmlSanitizer.cleanup(string)

=end

  def self.cleanup(string)
    string.gsub!(/<[A-z]:[A-z]>/, '')
    string.gsub!(%r{</[A-z]:[A-z]>}, '')
    string.delete!("\t")

    # remove all new lines
    string.gsub!(/(\n\r|\r\r\n|\r\n|\n)/, "\n")

    # remove double multiple empty lines
    string.gsub!(/\n\n\n+/, "\n\n")

    string = cleanup_structure(string, 'pre')
    string = cleanup_replace_tags(string)
    string = cleanup_structure(string)
    string
  end

  def self.cleanup_replace_tags(string)
    #return string
    tags_backlist = %w[span center]
    scrubber = Loofah::Scrubber.new do |node|
      next if !tags_backlist.include?(node.name)
      hit = false
      local_node = nil
      (1..5).each do |_count|
        local_node = if local_node
                       local_node.parent
                     else
                       node.parent
                     end
        break if !local_node
        next if local_node.name != 'td'
        hit = true
      end
      next if hit && node.keys.count.positive?
      node.replace cleanup_replace_tags(node.children.to_s)
      Loofah::Scrubber::STOP
    end
    Loofah.fragment(string).scrub!(scrubber).to_s
  end

  def self.cleanup_structure(string, type = 'all')
    remove_empty_nodes = if type == 'pre'
                           %w[span]
                         else
                           %w[p div span small table]
                         end
    remove_empty_last_nodes = %w[b i u small table]

    # remove last empty nodes and empty -not needed- parrent nodes
    scrubber_structure = Loofah::Scrubber.new do |node|
      if remove_empty_last_nodes.include?(node.name) && node.children.size.zero?
        node.remove
        Loofah::Scrubber::STOP
      end

      # remove empty childs
      if node.content.blank? && remove_empty_nodes.include?(node.name) && node.children.size == 1 && remove_empty_nodes.include?(node.children.first.name)
        node.replace node.children.to_s
        Loofah::Scrubber::STOP
      end

      # remove empty childs
      if remove_empty_nodes.include?(node.name) && node.children.size == 1 && remove_empty_nodes.include?(node.children.first.name) && node.children.first.content == node.content
        node.replace node.children.to_s
        Loofah::Scrubber::STOP
      end

      # remove node if empty and parent was already a remove node
      if node.content.blank? && remove_empty_nodes.include?(node.name) && node.parent && node.children.size.zero? && remove_empty_nodes.include?(node.parent.name)
        node.remove
        Loofah::Scrubber::STOP
      end
    end

    new_string = ''
    done = true
    while done
      new_string = Loofah.fragment(string).scrub!(scrubber_structure).to_s
      if string == new_string
        done = false
      end
      string = new_string
    end

    scrubber_cleanup = Loofah::Scrubber.new do |node|

      # remove mailto links
      if node['href']
        href = cleanup_target(node['href'])
        if href =~ /mailto:(.*)$/i
          text = Nokogiri::XML::Text.new($1, node.document)
          node.add_next_sibling(text)
          node.remove
          Loofah::Scrubber::STOP
        end
      end

      # remove not needed new lines
      if node.class == Nokogiri::XML::Text
        if !node.parent || (node.parent.name != 'pre' && node.parent.name != 'code')
          content = node.content
          if content
            if content != ' ' && content != "\n"
              content.gsub!(/[[:space:]]+/, ' ')
            end
            if node.previous
              if node.previous.name == 'div' || node.previous.name == 'p'
                content.strip!
              end
            elsif node.parent && !node.previous && (!node.next || node.next.name == 'div' || node.next.name == 'p' || node.next.name == 'br')
              if (node.parent.name == 'div' || node.parent.name == 'p') && content != ' ' && content != "\n"
                content.strip!
              end
            end
            node.content = content
          end
        end
      end
    end
    Loofah.fragment(string).scrub!(scrubber_cleanup).to_s
  end

  def self.add_link(content, urls, node)
    if urls.blank?
      text = Nokogiri::XML::Text.new(content, node.document)
      node.add_next_sibling(text)
      return
    end
    url = urls.shift

    if content =~ /^(.*)#{Regexp.quote(url)}(.*)$/mx
      pre = $1
      post = $2

      if url.match?(/^www/i)
        url = "http://#{url}"
      end

      a = Nokogiri::XML::Node.new 'a', node.document
      a['href'] = url
      a['rel'] = 'nofollow noreferrer noopener'
      a['target'] = '_blank'
      a.content = url

      if node.class != Nokogiri::XML::Text
        text = Nokogiri::XML::Text.new(pre, node.document)
        node.add_next_sibling(text).add_next_sibling(a)
        return if post.blank?
        add_link(post, urls, a)
        return
      end
      node.content = pre
      node.add_next_sibling(a)
      return if post.blank?
      add_link(post, urls, a)
    end

    true
  end

  def self.html_decode(string)
    string.gsub('&amp;', '&').gsub('&lt;', '<').gsub('&gt;', '>').gsub('&quot;', '"').gsub('&nbsp;', ' ')
  end

  def self.cleanup_target(string, **options)
    cleaned_string = CGI.unescape(string).utf8_encode(fallback: :read_as_sanitized_binary)
    cleaned_string = cleaned_string.gsub(/[[:space:]]/, '') if !options[:keep_spaces]
    cleaned_string = cleaned_string.strip
                                   .delete("\t\n\r\u0000")
                                   .gsub(%r{/\*.*?\*/}, '')
                                   .gsub(/<!--.*?-->/, '')
                                   .gsub(/\[.+?\]/, '')

    sanitize_attachment_disposition(cleaned_string)
  end

  def self.sanitize_attachment_disposition(url)
    uri = URI(url)

    if uri.host == Setting.get('fqdn') && uri.query.present?
      params = CGI.parse(uri.query || '')
                  .tap { |p| p.merge!('disposition' => 'attachment') if p.include?('disposition') }
      uri.query = URI.encode_www_form(params)
    end

    uri.to_s
  rescue URI::Error
    url
  end

  def self.url_same?(url_new, url_old)
    url_new = CGI.unescape(url_new.to_s).utf8_encode(fallback: :read_as_sanitized_binary).downcase.gsub(%r{/$}, '').gsub(/[[:space:]]|\t|\n|\r/, '').strip
    url_old = CGI.unescape(url_old.to_s).utf8_encode(fallback: :read_as_sanitized_binary).downcase.gsub(%r{/$}, '').gsub(/[[:space:]]|\t|\n|\r/, '').strip
    url_new = html_decode(url_new).sub('/?', '?')
    url_old = html_decode(url_old).sub('/?', '?')
    return true if url_new == url_old
    return true if url_old == "http://#{url_new}"
    return true if url_new == "http://#{url_old}"
    return true if url_old == "https://#{url_new}"
    return true if url_new == "https://#{url_old}"
    false
  end

=begin

reolace inline images with cid images

  string = HtmlSanitizer.replace_inline_images(article.body)

=end

  def self.replace_inline_images(string, prefix = rand(999_999_999))
    attachments_inline = []
    filename_counter = 0
    scrubber = Loofah::Scrubber.new do |node|
      if node.name == 'img'
        if node['src'] && node['src'] =~ %r{^(data:image/(jpeg|png);base64,.+?)$}i
          filename_counter += 1
          file_attributes = StaticAssets.data_url_attributes($1)
          cid = "#{prefix}.#{rand(999_999_999)}@#{Setting.get('fqdn')}"
          filename = cid
          if file_attributes[:file_extention].present?
            filename = "image#{filename_counter}.#{file_attributes[:file_extention]}"
          end
          attachment = {
            data: file_attributes[:content],
            filename: filename,
            preferences: {
              'Content-Type' => file_attributes[:mime_type],
              'Mime-Type' => file_attributes[:mime_type],
              'Content-ID' => cid,
              'Content-Disposition' => 'inline',
            },
          }
          attachments_inline.push attachment
          node['src'] = "cid:#{cid}"
        end
        Loofah::Scrubber::STOP
      end
    end
    [Loofah.fragment(string).scrub!(scrubber).to_s, attachments_inline]
  end

=begin

satinize style of img tags

  string = HtmlSanitizer.dynamic_image_size(article.body)

=end

  def self.dynamic_image_size(string)
    scrubber = Loofah::Scrubber.new do |node|
      if node.name == 'img'
        if node['src']
          style = 'max-width:100%;'
          if node['style']
            pears = node['style'].downcase.gsub(/\t|\n|\r/, '').split(';')
            pears.each do |local_pear|
              prop = local_pear.split(':')
              next if !prop[0]
              key = prop[0].strip
              if key == 'height'
                key = 'max-height'
              end
              style += "#{key}:#{prop[1]};"
            end
          end
          node['style'] = style
        end
        Loofah::Scrubber::STOP
      end
    end
    Loofah.fragment(string).scrub!(scrubber).to_s
  end

  private_class_method :cleanup_target
  private_class_method :sanitize_attachment_disposition
  private_class_method :add_link
  private_class_method :url_same?
  private_class_method :html_decode

end
