# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ScrubHtml
  attr_reader :string, :scrubbers, :chunk

  REGEXP_CHARSET = %r{<meta\s+[^>]*charset\s*=\s*["']?\s*(?<charset>[^"'/>\s]+)}i
  REGEXP_UTF8    = %r{\Autf-?8\z}i

  def initialize(string, scrubbers, chunk: :fragment)
    @string    = string
    @scrubbers = Array(scrubbers)
    @chunk     = chunk
  end

  def scrub!
    scrub_html5
  rescue => e
    return rescrub if depth_limit_error?(e)

    raise e
  end

  private

  def rescrub
    ensure_encoding!

    @string = ScrubHtml::DivRemovingStreamParser.parse(string, chunk:)

    scrub_html5
  end

  def depth_limit_error?(e)
    e.is_a?(ArgumentError) && e.message == 'Document tree depth limit exceeded'
  end

  def scrub_html5
    scrubbers.reduce(loofah_by_chunk) do |memo, elem|
      memo.scrub!(elem)
    end
  end

  def loofah_by_chunk
    case chunk
    when :document
      Loofah.html5_document(string)
    when :fragment
      Loofah.html5_fragment(string)
    end
  end

  # SAX parser uses encoding present in HTML is such is present
  # Thus string has to be in the correct encoding before parsing
  def ensure_encoding!
    charset = string.match(REGEXP_CHARSET)&.[](:charset)

    return if !charset
    return if charset.match?(REGEXP_UTF8) # Ruby string is UTF-8 anyway

    @string = string.encode(charset)
  rescue EncodingError
    # ignore encoding errors
  end
end
