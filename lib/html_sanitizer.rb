# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  PROCESSING_TIMEOUT     = Setting.get('html_sanitizer_processing_timeout').to_i.seconds
  UNPROCESSABLE_HTML_MSG = __('This message cannot be displayed due to HTML processing issues. Download the raw message below and open it via an Email client if you still wish to view it.').freeze

=begin

sanitize html string based on whiltelist

  string = HtmlSanitizer.strict(string, external)

=end

  def self.strict(string, external = false, timeout: true)
    HtmlSanitizer::Strict.new.sanitize(string, external: external, timeout: timeout)
  end

=begin

cleanup html string:

 * remove empty nodes (p, div, span, table)
 * remove nodes in general (keep content - span)

  string = HtmlSanitizer.cleanup(string)

=end

  def self.cleanup(string, timeout: true)
    HtmlSanitizer::Cleanup.new.sanitize(string, timeout: timeout)
  end

=begin

replace inline images with cid images

  string = HtmlSanitizer.replace_inline_images(article.body)

=end

  def self.replace_inline_images(string, prefix = SecureRandom.uuid)
    HtmlSanitizer::ReplaceInlineImages.new.sanitize(string, prefix)
  end

=begin

sanitize style of img tags

  string = HtmlSanitizer.dynamic_image_size(article.body)

=end

  def self.dynamic_image_size(string)
    HtmlSanitizer::DynamicImageSize.new.sanitize(string)
  end

=begin

Adjust image size in html email for MS Outlook to always contain `width` and `height` as tags, not only as part of the `style`.

  string = HtmlSanitizer.adjust_inline_image_size(article.body)

=end

  def self.adjust_inline_image_size(string)
    HtmlSanitizer::AdjustInlineImageSize.new.sanitize(string)
  end

end
