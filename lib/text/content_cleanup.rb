# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Text
  class ContentCleanup
    attr_reader :content

    def initialize(content:)
      @content = content
    end

    def cleanup
      text = content.html2text(link_style: :plain)

      # Remove special symbols unlikely to be searched: emojis, pictograms, dingbats, pilcrows, etc.
      text.gsub!(%r{[\p{So}¶§]}, '')

      # Remove duplicated characters which may serve as delimiters.
      text.gsub!(%r{[\^\#*\-_]{2,}}, ' ')

      # Compress runs of horizontal whitespace longer than 2 to exactly 1.
      text.gsub!(%r{[ \t]{2,}}, ' ')

      # Compress runs of newlines longer than 3 to exactly 2.
      text.gsub!(%r{\n{3,}}, "\n\n")

      text.strip
    end
  end
end
