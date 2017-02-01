class HtmlSanitizer

  def self.strict(string)
    remove = %w(style body head)
    strip = ['script']

    scrubber = Loofah::Scrubber.new do |node|

      # strip tags
      if strip.include?(node.name)
        node.before node.children
        node.remove
      end

      # remove tags
      if remove.include?(node.name)
        node.remove
      end

      # prepare src attribute
      if node['src']
        if node['src'].downcase.start_with?('http', 'ftp')
          node.before node.children
          node.remove
        end
      end

      # prepare links
      if node['href']
        if node['href'].downcase.start_with?('http', 'ftp')
          node.set_attribute('rel', 'nofollow')
          node.set_attribute('target', '_blank')
        end
        if node['href'] =~ /javascript/i
          node.delete('href')
        end
      end

      # remove on* attributes
      node.each { |attribute, _value|
        next if !attribute.downcase.start_with?('on')
        node.delete(attribute)
      }
    end
    Loofah.fragment(string).scrub!(scrubber).to_s
  end

end
