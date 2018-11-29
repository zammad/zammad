module Diffy
  module Format
    # ANSI color output suitable for terminal output
    def color
      map do |line|
        case line          
        when /^(---|\+\+\+|\\\\)/
          "\033[90m#{line.chomp}\033[0m"
        when /^\+/
          "\033[32m#{line.chomp}\033[0m"
        when /^-/
          "\033[31m#{line.chomp}\033[0m"
        when /^@@/
          "\033[36m#{line.chomp}\033[0m"
        else
          line.chomp
        end
      end.join("\n") + "\n"
    end

    # Basic text output
    def text
      to_a.join
    end

    # Basic html output which does not attempt to highlight the changes
    # between lines, and is more performant.
    def html_simple
      HtmlFormatter.new(self, options).to_s
    end

    # Html output which does inline highlighting of changes between two lines.
    def html
      HtmlFormatter.new(self, options.merge(:highlight_words => true)).to_s
    end
  end
end
