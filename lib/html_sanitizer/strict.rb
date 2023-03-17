# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class Strict < Base
    def initialize(no_images: false)
      super()

      @no_images = no_images
    end

    def sanitize(string, external: false, timeout: true)
      return run_sanitization(string, external) if !timeout

      with_timeout(string) do
        run_sanitization(string, external)
      end
    end

    private

    def run_sanitization(string, external)
      fragment = Loofah
        .fragment(string)
        .scrub!(HtmlSanitizer::Scrubber::TagRemove.new)
        .scrub!(HtmlSanitizer::Scrubber::QuoteContent.new)

      if @no_images
        fragment.scrub! HtmlSanitizer::Scrubber::TagRemove.new(tags: %w[img])
      end

      wipe_scrubber = HtmlSanitizer::Scrubber::Wipe.new

      string = loop_string(fragment.to_html, wipe_scrubber)

      link_scrubber = HtmlSanitizer::Scrubber::Link.new(web_app_url_prefix: web_app_url_prefix, external: external)
      Loofah.fragment(string).scrub!(link_scrubber).to_html
    end

    def web_app_url_prefix
      fqdn      = Setting.get('fqdn')
      http_type = Setting.get('http_type')

      "#{http_type}://#{fqdn}/#".downcase
    end
  end
end
