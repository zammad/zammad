# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::EmailParser::MessageWalker
  attr_reader :mail, :raw_html

  def initialize(mail, raw_html: false)
    @mail     = mail
    @raw_html = raw_html
  end

  def process_message_body
    content = ''
    content_type = nil
    sanitized_body_info = nil

    walk_message_parts(mail) do |part, style|
      (local_body, local_content_type, local_sanitized_body_info) = process_single_message_part(part, style:, raw_html:)

      content += local_body if local_body.present?

      if local_content_type == 'text/html' || content_type.blank?
        content_type = local_content_type
      end

      if local_sanitized_body_info.present? && local_sanitized_body_info[:remote_content_removed]
        sanitized_body_info = { remote_content_removed: true }
      end
    end

    [content, content_type, sanitized_body_info]
  end

  private

  def process_single_message_part(part, style:, raw_html:)
    content_type        = style == :text ? 'text/plain' : 'text/html'
    sanitized_body_info = nil

    body = case style
           when :html
             return if part.body.blank?

             (content, sanitized_body_info) = body_text(part, strict_html: !raw_html)
             content
           when :text
             return if part.body.blank?

             body_text(part).first
           when :text_as_html
             return if part.body.blank?

             body_text(part).first.text2html
           when :inline_image
             "<img src='cid:#{part.cid}'>"
           end

    [body, content_type, sanitized_body_info]
  end

  def walk_message_parts(part, force_html: false, &)
    if part.multipart?
      walk_multi_part(part, force_html:, &)
    else
      walk_single_part(part, force_html:, &)
    end
  end

  def walk_single_part(part, force_html:, &)
    text_style = force_html ? :text_as_html : :text

    if part.attachment?
      if part_inline_image?(part)
        yield part, :inline_image
      end
    elsif part.content_type&.start_with?('text/html')
      yield part, :html
    elsif part.html_part.present?
      yield part.html_part, :html
    elsif part.text_part.present?
      yield part.text_part, text_style
    elsif part_plaintext_like?(part)
      yield part, text_style
    end
  end

  def walk_multi_part(part, force_html:, &)
    content_type = part.content_type

    if content_type&.start_with?('multipart/mixed')
      walk_multipart_mixed(part, force_html:, &)
    elsif content_type&.start_with?('multipart/related')
      walk_multipart_related(part, force_html:, &)
    elsif content_type&.start_with?('multipart/alternative')
      mixed = part.parts.find { |p| p.content_type&.start_with?('multipart/mixed') }

      if mixed&.multipart?
        walk_multipart_mixed(mixed, force_html:, &)
      else
        multipart_fallback(part, &)
      end
    else
      multipart_fallback(part, &)
    end
  end

  def multipart_fallback(part, &)
    if part.html_part.present?
      yield part.html_part, :html
    elsif part.text_part.present?
      yield part.text_part, :text
    end
  end

  def walk_multipart_mixed(part, force_html:, &)
    has_html = part.parts.any? { |p| p.content_type&.start_with?('text/html') || p.html_part.present? }
    has_inline_attachment = part.parts.any? { |p| p.attachment? && part_inline_image?(p) }

    part.parts.each do |sub_part|
      walk_message_parts(sub_part, force_html: has_html || has_inline_attachment, &)
    end
  end

  def walk_multipart_related(part, force_html:, &)
    if part.html_part.present?
      yield part.html_part, :html
    elsif part.text_part.present?
      has_inline_attachment = part.parts.any? { |p| p.attachment? && part_inline_image?(p) }

      part.parts.each do |sub_part|
        walk_message_parts(sub_part, force_html: has_inline_attachment, &)
      end
    end
  end

  def body_text(message, **options)
    body_text = begin
      message.body.to_s
    rescue Mail::UnknownEncodingType # see test/data/mail/mail043.box / issue #348
      message.body.raw_source
    end

    body_text = body_text.utf8_encode(from: message.charset, fallback: :read_as_sanitized_binary)
    body_text = Mail::Utilities.to_lf(body_text)

    # plaintext body requires no processing
    return [body_text, {}] if !options[:strict_html]

    # Issue #2390 - emails with >5k HTML links should be rejected
    return [Channel::EmailParser::EXCESSIVE_LINKS_MSG, {}] if body_text.scan(%r{<a[[:space:]]}i).count >= 5_000

    body_text.html2html_strict
  end

  def part_inline_image?(part)
    return false if !part.is_a?(Mail::Part)

    part.inline? && part.content_type&.start_with?('image')
  end

  def part_plaintext_like?(part)
    return true if part.content_type&.start_with?('text/plain')

    part.body.present? && part.content_type.nil? && part.html_part.nil? && part.text_part.nil?
  end
end
