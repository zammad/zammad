# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class RemoveLineBreaks < Loofah::Scrubber
    SPAN_LINE_BREAKS = ["\n", "\r", "\r\n"].freeze
    DIV_LINE_BREAK_REGEXP = %r{\A([\n\r]+)\z}

    def scrub(node)
      case node.name
      when 'span'
        node.children.reject { |t| SPAN_LINE_BREAKS.include?(t.text) }.each { |child| node.before child }

        node.remove
      when 'div'
        node.children.to_a.select { |t| t.text.match?(DIV_LINE_BREAK_REGEXP) }.each(&:remove)

        node.remove if node.children.none? && node.classes.none?
      end
    end
  end
end
