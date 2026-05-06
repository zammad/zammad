# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class Strict < Base
    attr_reader :remote_content_removed

    def initialize(no_images: false)
      super()

      @no_images              = no_images
      @remote_content_removed = false
    end

    def sanitize(string, external: false, timeout: true)
      return run_sanitization(string, external) if !timeout

      with_timeout(string) do
        run_sanitization(string, external)
      end
    end

    private

    def run_sanitization(string, external)
      scrubbers = [HtmlSanitizer::Scrubber::TagRemove.new, HtmlSanitizer::Scrubber::QuoteContent.new]

      if @no_images
        scrubbers << HtmlSanitizer::Scrubber::TagRemove.new(tags: %w[img])
      end

      scrubbed = ScrubHtml.new(string, scrubbers).scrub!

      wipe_scrubber = HtmlSanitizer::Scrubber::Wipe.new

      string = loop_string(scrubbed.to_html, wipe_scrubber)

      @remote_content_removed = wipe_scrubber.remote_content_removed

      link_scrubber = HtmlSanitizer::Scrubber::Link.new(web_app_url_prefix: web_app_url_prefix, external: external)
      result = ScrubHtml.new(string, link_scrubber).scrub!.to_html

      # The HTML5 parser/serializer percent-encodes '{' and '}' in URL attribute values
      # (e.g. href, title), since they are not valid URL code points. This breaks
      # Zammad variable placeholders like #{ticket.number} in URLs. Decode them back,
      # but only within href and title attribute values to avoid affecting other content.
      # Note: [^"]* is safe here because Nokogiri's HTML5 serializer encodes literal '"'
      # as '&quot;' (which contains no '"' character), so [^"]* correctly captures the
      # full attribute value up to the closing double-quote.
      result.gsub(%r{(?<attr>href|title)="(?<value>[^"]*)"}) do
        attr_name  = Regexp.last_match(:attr)
        attr_value = Regexp.last_match(:value).gsub(/%7B/i, '{').gsub(/%7D/i, '}')
        "#{attr_name}=\"#{attr_value}\""
      end
    end

    def web_app_url_prefix
      fqdn      = Setting.get('fqdn')
      http_type = Setting.get('http_type')

      "#{http_type}://#{fqdn}/#".downcase
    end
  end
end
