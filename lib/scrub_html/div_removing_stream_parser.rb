# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ScrubHtml
  # SAX handler that collapses empty nested divs while preserving content.
  # This reduces document depth by removing wrapper divs that contain only other divs
  # (no direct text content or non-div elements), while keeping divs with actual content.
  #
  # A div is considered "meaningful" and kept if it has:
  # - Direct non-whitespace text content
  # - Non-div child elements
  # - Attributes (like class, id, style)
  #
  # Wrapper divs that only contain other divs are collapsed.
  # Additionally, a hard MAX_DIV_DEPTH limit prevents extreme nesting.
  class DivRemovingStreamParser < Nokogiri::XML::SAX::Document
    MAX_DIV_DEPTH = 20

    attr_reader :out, :chunk

    def initialize(chunk: :fragment)
      super()

      @chunk = chunk

      @out = +''
      # Stack of div frames: { tag: '<div ...>', buffer: '...', has_direct_content: bool }
      @div_stack = []
      @skip_div = 0 # Counter for divs beyond MAX_DIV_DEPTH that we're skipping
    end

    # This is the main entry point for parsing a string to remove deeply nested divs.
    #
    # @param string [String] The HTML string to parse.
    # @param chunk [Symbol] :fragment or :document to indicate parsing mode.
    def self.parse(string, chunk: :fragment)
      handler = new(chunk:)

      parser = Nokogiri::HTML::SAX::Parser.new(handler)
      parser.parse(string)

      handler.out
    end

    def start_element(name, attrs = [])
      # Skip html/body wrapper tags added by SAX parser for fragments
      return if chunk != :document && %w[html body].include?(name)

      if name == 'div'
        # Hard limit: skip divs beyond MAX_DIV_DEPTH entirely
        if @div_stack.size >= MAX_DIV_DEPTH
          @skip_div += 1
          return
        end

        # Push a new frame - don't write the div yet, we'll decide on close
        @div_stack.push({
                          tag:                build_tag(name, attrs),
                          buffer:             +'',
                          has_direct_content: attrs.any? # divs with attributes are considered "meaningful"
                        })
      else
        # Non-div element: mark current div as having direct content and write to buffer
        mark_has_direct_content
        current_buffer << build_tag(name, attrs)
      end
    end

    def end_element(name)
      # Skip html/body wrapper tags added by SAX parser for fragments
      return if chunk != :document && %w[html body].include?(name)

      if name == 'div'
        # Handle closing tags for skipped divs
        if @skip_div.positive?
          @skip_div -= 1
          return
        end

        return if @div_stack.empty?

        frame = @div_stack.pop

        if frame[:has_direct_content]
          # This div has direct content - include it with wrapper
          write_to_parent("#{frame[:tag]}#{frame[:buffer]}</div>")
        else
          # Pure wrapper div - pass through inner content without the wrapper
          write_to_parent(frame[:buffer])
        end
      else
        # For non-div elements, just output the closing tag
        # (void elements like <br> will have end_element called but that's fine -
        # the resulting </br> gets cleaned up by subsequent HTML parsing)
        current_buffer << "</#{name}>"
      end
    end

    def characters(string)
      escaped = CGI.escapeHTML(string)
      current_buffer << escaped

      # Non-whitespace text means direct content
      mark_has_direct_content if string.match?(%r{\S})
    end

    private

    def build_tag(name, attrs)
      tag = "<#{name}"
      attrs.each do |attr|
        attr_name, attr_value = attr
        tag << " #{attr_name}=\"#{CGI.escapeHTML(attr_value.to_s)}\""
      end
      tag << '>'
      tag
    end

    def current_buffer
      @div_stack.any? ? @div_stack.last[:buffer] : @out
    end

    def write_to_parent(content)
      if @div_stack.any?
        @div_stack.last[:buffer] << content
      else
        @out << content
      end
    end

    def mark_has_direct_content
      @div_stack.last[:has_direct_content] = true if @div_stack.any?
    end
  end
end
