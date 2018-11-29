require "nokogiri"

class Nori
  module Parser

    # = Nori::Parser::Nokogiri
    #
    # Nokogiri SAX parser.
    module Nokogiri

      class Document < ::Nokogiri::XML::SAX::Document
        attr_accessor :options

        def stack
          @stack ||= []
        end

        def start_element(name, attrs = [])
          stack.push Nori::XMLUtilityNode.new(options, name, Hash[*attrs.flatten])
        end

        # To keep backward behaviour compatibility
        # delete last child if it is a space-only text node
        def end_element(name)
          if stack.size > 1
            last = stack.pop
            maybe_string = last.children.last
            if maybe_string.is_a?(String) and maybe_string.strip.empty?
              last.children.pop
            end
            stack.last.add_node last
          end
        end

        # If this node is a successive character then add it as is.
        # First child being a space-only text node will not be added
        # because there is no previous characters.
        def characters(string)
          last = stack.last
          if last and last.children.last.is_a?(String) or string.strip.size > 0
            last.add_node(string)
          end
        end

        alias cdata_block characters

      end

      def self.parse(xml, options)
        document = Document.new
        document.options = options
        parser = ::Nokogiri::XML::SAX::Parser.new document
        parser.parse xml
        document.stack.length > 0 ? document.stack.pop.to_hash : {}
      end

    end
  end
end
