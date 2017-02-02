class HtmlSanitizer

  def self.strict(string)

    # config
    tags_remove_content = Rails.configuration.html_sanitizer_tags_remove_content
    tags_whitelist = Rails.configuration.html_sanitizer_tags_whitelist
    attributes_whitelist = Rails.configuration.html_sanitizer_attributes_whitelist
    css_properties_whitelist = Rails.configuration.html_sanitizer_css_properties_whitelist

    scrubber = Loofah::Scrubber.new do |node|

      # remove tags with subtree
      if tags_remove_content.include?(node.name)
        node.remove
      end

      # replace tags, keep subtree
      if !tags_whitelist.include?(node.name)
        traversal(node, scrubber)
      end

      # prepare src attribute
      if node['src']
        src = cleanup(node['src'])
        if src =~ /(javascript|livescript|vbscript):/i || src.start_with?('http', 'ftp', '//')
          traversal(node, scrubber)
        end
      end

      # clean style / only use allowed style properties
      if node['style']
        pears = node['style'].downcase.gsub(/\t|\n|\r/, '').split(';')
        style = ''
        pears.each { |pear|
          prop = pear.split(':')
          next if !prop[0]
          key = prop[0].strip
          next if !css_properties_whitelist.include?(key)
          style += "#{pear};"
        }
        node['style'] = style
        if style == ''
          node.delete('style')
        end
      end

      # scan for invalid link content
      %w(href style).each { |attribute_name|
        next if !node[attribute_name]
        href = cleanup(node[attribute_name])
        next if href !~ /(javascript|livescript|vbscript):/i
        node.delete(attribute_name)
      }

      # remove attributes if not whitelisted
      node.each { |attribute, _value|
        attribute_name = attribute.downcase
        next if attributes_whitelist[:all].include?(attribute_name) || (attributes_whitelist[node.name] && attributes_whitelist[node.name].include?(attribute_name))
        node.delete(attribute)
      }

      # prepare links
      if node['href']
        href = cleanup(node['href'])
        next if !href.start_with?('http', 'ftp', '//')
        node.set_attribute('rel', 'nofollow')
        node.set_attribute('target', '_blank')
      end
    end
    Loofah.fragment(string).scrub!(scrubber).to_s
  end

  def self.traversal(node, scrubber)
    node.children.each { |child|
      if child.class == Nokogiri::XML::CDATA
        node.before Nokogiri::XML::Text.new(node.content, node.document)
      else
        node.before Loofah.fragment(child.to_s).scrub!(scrubber)
      end
    }
    node.remove
  end

  def self.cleanup(string)
    string.downcase.gsub(/[[:space:]]|\t|\n|\r/, '').gsub(%r{/\*.*?\*/}, '').gsub(/<!--.*?-->/, '').gsub(/\[.+?\]/, '')
  end

  private_class_method :traversal
  private_class_method :cleanup

end
