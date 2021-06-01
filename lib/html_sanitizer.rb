# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class HtmlSanitizer
  LINKABLE_URL_SCHEMES = URI.scheme_list.keys.map(&:downcase) - ['mailto'] + ['tel']
  PROCESSING_TIMEOUT = 20
  UNPROCESSABLE_HTML_MSG = 'This message cannot be displayed due to HTML processing issues. Download the raw message below and open it via an Email client if you still wish to view it.'.freeze

=begin

satinize html string based on whiltelist

  string = HtmlSanitizer.strict(string, external)

=end

  def self.strict(string, external = false, timeout: true)
    Timeout.timeout(timeout ? PROCESSING_TIMEOUT : nil) do
      @fqdn              = Setting.get('fqdn')
      http_type          = Setting.get('http_type')
      web_app_url_prefix = "#{http_type}://#{@fqdn}/\#".downcase

      # config
      tags_remove_content = Rails.configuration.html_sanitizer_tags_remove_content
      tags_quote_content = Rails.configuration.html_sanitizer_tags_quote_content
      tags_whitelist = Rails.configuration.html_sanitizer_tags_whitelist
      attributes_whitelist = Rails.configuration.html_sanitizer_attributes_whitelist
      css_properties_whitelist = Rails.configuration.html_sanitizer_css_properties_whitelist
      css_values_blacklist = Rails.application.config.html_sanitizer_css_values_backlist

      # We whitelist yahoo_quoted because Yahoo Mail marks quoted email content using
      # <div class='yahoo_quoted'> and we rely on this class to identify quoted messages
      classes_whitelist = %w[js-signatureMarker yahoo_quoted]
      attributes_2_css = %w[width height]

      # remove tags with subtree
      scrubber_tag_remove = Loofah::Scrubber.new do |node|
        next if tags_remove_content.exclude?(node.name)

        node.remove
        Loofah::Scrubber::STOP
      end
      string = Loofah.fragment(string).scrub!(scrubber_tag_remove).to_s

      # remove tag, insert quoted content
      scrubber_wipe_quote_content = Loofah::Scrubber.new do |node|
        next if tags_quote_content.exclude?(node.name)

        string = html_decode(node.content)
        text = Nokogiri::XML::Text.new(string, node.document)
        node.add_next_sibling(text)
        node.remove
        Loofah::Scrubber::STOP
      end
      string = Loofah.fragment(string).scrub!(scrubber_wipe_quote_content).to_s

      scrubber_wipe = Loofah::Scrubber.new do |node|

        # replace tags, keep subtree
        if tags_whitelist.exclude?(node.name)
          node.replace node.children.to_s
          Loofah::Scrubber::STOP
        end

        # prepare src attribute
        if node['src']
          src = cleanup_target(CGI.unescape(node['src']))
          if src =~ %r{(javascript|livescript|vbscript):}i || src.downcase.start_with?('http', 'ftp', '//')
            node.remove
            Loofah::Scrubber::STOP
          end
        end

        # clean class / only use allowed classes
        if node['class']
          classes = node['class'].gsub(%r{\t|\n|\r}, '').split
          class_new = ''
          classes.each do |local_class|
            next if classes_whitelist.exclude?(local_class.to_s.strip)

            if class_new != ''
              class_new += ' '
            end
            class_new += local_class
          end
          if class_new == ''
            node.delete('class')
          else
            node['class'] = class_new
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

          value += 'px' if !value.match?(%r{%|px|em}i)
          node['style'] += "#{key}:#{value}"
        end

        # clean style / only use allowed style properties
        if node['style']
          pears = node['style'].downcase.gsub(%r{\t|\n|\r}, '').split(';')
          style = ''
          pears.each do |local_pear|
            prop = local_pear.split(':')
            next if !prop[0]

            key = prop[0].strip
            next if css_properties_whitelist.exclude?(node.name)
            next if css_properties_whitelist[node.name].exclude?(key)
            next if css_values_blacklist[node.name]&.include?(local_pear.gsub(%r{[[:space:]]}, '').strip)

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
          next if !href.match?(%r{(javascript|livescript|vbscript):}i)

          node.delete(attribute_name)
        end

        # remove attributes if not whitelisted
        node.each do |attribute, _value|
          attribute_name = attribute.downcase
          next if attributes_whitelist[:all].include?(attribute_name) || attributes_whitelist[node.name]&.include?(attribute_name)

          node.delete(attribute)
        end

      end

      done = true
      while done
        new_string = Loofah.fragment(string).scrub!(scrubber_wipe).to_s
        if string == new_string
          done = false
        end
        string = new_string
      end

      scrubber_link = Loofah::Scrubber.new do |node|

        # wrap plain-text URLs in <a> tags
        if node.is_a?(Nokogiri::XML::Text) && node.content.present? && node.content.include?(':') && node.ancestors.map(&:name).exclude?('a')
          urls = URI.extract(node.content, LINKABLE_URL_SCHEMES)
                    .map { |u| u.sub(%r{[,.]$}, '') }      # URI::extract captures trailing dots/commas
                    .reject { |u| u.match?(%r{^[^:]+:$}) } # URI::extract will match, e.g., 'tel:'

          next if urls.blank?

          add_link(node.content, urls, node)
        end

        # prepare links
        if node['href']
          href                = cleanup_target(node['href'], keep_spaces: true)
          href_without_spaces = href.gsub(%r{[[:space:]]}, '')
          if external && href_without_spaces.present? && !href_without_spaces.downcase.start_with?('mailto:') && !href_without_spaces.downcase.start_with?('//') && href_without_spaces.downcase !~ %r{^.{1,6}://.+?}
            node['href']        = "http://#{node['href']}"
            href                = node['href']
            href_without_spaces = href.gsub(%r{[[:space:]]}, '')
          end

          next if !CGI.unescape(href_without_spaces).utf8_encode(fallback: :read_as_sanitized_binary).gsub(%r{[[:space:]]}, '').downcase.start_with?('http', 'ftp', '//')

          node.set_attribute('href', href)
          node.set_attribute('rel', 'nofollow noreferrer noopener')

          # do not "target=_blank" WebApp URLs (e.g. mentions)
          if !href.downcase.start_with?(web_app_url_prefix)
            node.set_attribute('target', '_blank')
          end
        end

        if node.name == 'a' && node['href'].blank?
          node.replace node.children.to_s
          Loofah::Scrubber::STOP
        end

        # check if href is different to text
        if node.name == 'a' && !url_same?(node['href'], node.text) && node['title'].blank?
          node['title'] = node['href']
        end
      end

      Loofah.fragment(string).scrub!(scrubber_link).to_s
    end
  rescue Timeout::Error
    Rails.logger.error "Could not process string via HtmlSanitizer.strict in #{PROCESSING_TIMEOUT} seconds. Current state: #{string}"
    UNPROCESSABLE_HTML_MSG
  end

=begin

cleanup html string:

 * remove empty nodes (p, div, span, table)
 * remove nodes in general (keep content - span)

  string = HtmlSanitizer.cleanup(string)

=end

  def self.cleanup(string, timeout: true)
    Timeout.timeout(timeout ? PROCESSING_TIMEOUT : nil) do
      string.gsub!(%r{<[A-z]:[A-z]>}, '')
      string.gsub!(%r{</[A-z]:[A-z]>}, '')
      string.delete!("\t")

      # remove all new lines
      string.gsub!(%r{(\n\r|\r\r\n|\r\n|\n)}, "\n")

      # remove double multiple empty lines
      string.gsub!(%r{\n\n\n+}, "\n\n")

      string = cleanup_structure(string, 'pre')
      string = cleanup_structure(string)
      string
    end
  rescue Timeout::Error
    Rails.logger.error "Could not process string via HtmlSanitizer.cleanup in #{PROCESSING_TIMEOUT} seconds. Current state: #{string}"
    UNPROCESSABLE_HTML_MSG
  end

  def self.remove_last_empty_node(node, remove_empty_nodes, remove_empty_last_nodes)
    if node.children.present?
      if node.children.size == 1
        local_name = node.name
        child = node.children.first

        # replace not needed node (parent <- child)
        if local_name == child.name && node.attributes.present? && node.children.first.attributes.blank?
          local_node_child = node.children.first
          node.attributes.each do |k|
            local_node_child.set_attribute(k[0], k[1])
          end
          node.replace local_node_child.to_s
          Loofah::Scrubber::STOP

        # replace not needed node (parent replace with child node)
        elsif (local_name == 'span' || local_name == child.name) && node.attributes.blank?
          node.replace node.children.to_s
          Loofah::Scrubber::STOP
        end
      else

        # loop through nodes
        node.children.each do |local_node|
          remove_last_empty_node(local_node, remove_empty_nodes, remove_empty_last_nodes)
        end
      end
    # remove empty nodes
    elsif (remove_empty_nodes.include?(node.name) || remove_empty_last_nodes.include?(node.name)) && node.content.blank? && node.attributes.blank?
      node.remove
      Loofah::Scrubber::STOP
    end
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
      remove_last_empty_node(node, remove_empty_nodes, remove_empty_last_nodes)
    end

    done = true
    while done
      new_string = Loofah.fragment(string).scrub!(scrubber_structure).to_s
      if string == new_string
        done = false
      end
      string = new_string
    end

    scrubber_cleanup = Loofah::Scrubber.new do |node|

      # remove not needed new lines
      if node.instance_of?(Nokogiri::XML::Text)
        if !node.parent || (node.parent.name != 'pre' && node.parent.name != 'code') # rubocop:disable Style/SoleNestedConditional
          content = node.content
          if content
            if content != ' ' && content != "\n"
              content.gsub!(%r{[[:space:]]+}, ' ')
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

    if content =~ %r{^(.*)#{Regexp.quote(url)}(.*)$}mx
      pre = $1
      post = $2

      if url.match?(%r{^www}i)
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
    cleaned_string = string.utf8_encode(fallback: :read_as_sanitized_binary)
    cleaned_string = cleaned_string.gsub(%r{[[:space:]]}, '') if !options[:keep_spaces]
    cleaned_string = cleaned_string.strip
                                   .delete("\t\n\r\u0000")
                                   .gsub(%r{/\*.*?\*/}, '')
                                   .gsub(%r{<!--.*?-->}, '')

    sanitize_attachment_disposition(cleaned_string)
  end

  def self.sanitize_attachment_disposition(url)
    @fqdn ||= Setting.get('fqdn')
    uri = URI(url)

    if uri.host == @fqdn && uri.query.present?
      params = CGI.parse(uri.query || '')
                  .tap { |p| p.merge!('disposition' => 'attachment') if p.include?('disposition') }
      uri.query = URI.encode_www_form(params)
    end

    uri.to_s
  rescue
    url
  end

  def self.url_same?(url_new, url_old)
    url_new = CGI.unescape(url_new.to_s).utf8_encode(fallback: :read_as_sanitized_binary).downcase.delete_suffix('/').gsub(%r{[[:space:]]|\t|\n|\r}, '').strip
    url_old = CGI.unescape(url_old.to_s).utf8_encode(fallback: :read_as_sanitized_binary).downcase.delete_suffix('/').gsub(%r{[[:space:]]|\t|\n|\r}, '').strip
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
    fqdn = Setting.get('fqdn')
    attachments_inline = []
    filename_counter = 0
    scrubber = Loofah::Scrubber.new do |node|
      if node.name == 'img'
        if node['src'] && node['src'] =~ %r{^(data:image/(jpeg|png);base64,.+?)$}i
          filename_counter += 1
          file_attributes = StaticAssets.data_url_attributes($1)
          cid = "#{prefix}.#{rand(999_999_999)}@#{fqdn}"
          filename = cid
          if file_attributes[:file_extention].present?
            filename = "image#{filename_counter}.#{file_attributes[:file_extention]}"
          end
          attachment = {
            data:        file_attributes[:content],
            filename:    filename,
            preferences: {
              'Content-Type'        => file_attributes[:mime_type],
              'Mime-Type'           => file_attributes[:mime_type],
              'Content-ID'          => cid,
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
            pears = node['style'].downcase.gsub(%r{\t|\n|\r}, '').split(';')
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
