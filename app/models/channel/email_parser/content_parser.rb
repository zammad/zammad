# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::EmailParser::ContentParser
  attr_reader :mail

  def initialize(mail)
    @mail = mail
  end

  def message_body_hash
    (body, content_type, sanitized_body_info) = Channel::EmailParser::MessageWalker.new(mail).process_message_body

    content_type = 'text/plain' if body.blank?

    {
      attachments:         collect_attachments,
      content_type:        content_type || 'text/plain',
      body:                body.presence || 'no visible content',
      sanitized_body_info: sanitized_body_info || {},
    }.with_indifferent_access
  end

  private

  def collect_attachments
    [
      *nonplaintext_body_as_attachment, # get raw HTML message as an attachment
      *gracefully_get_attachments # get all attachments, including body-as-attachment
    ]
  end

  def nonplaintext_body_as_attachment
    (raw_body, raw_content_type,) = Channel::EmailParser::MessageWalker.new(mail, raw_html: true).process_message_body

    return if raw_content_type != 'text/html' || raw_body.blank?

    html_part = mail.html_part || mail

    filename = html_part.filename.presence || 'message.html'

    headers_store = {
      'content-alternative' => true,
      'original-format'     => raw_content_type == 'text/html',
      'Mime-Type'           => raw_content_type,
      'Charset'             => html_part.charset,
    }.compact_blank

    [{
      data:        raw_body,
      filename:    filename,
      preferences: headers_store
    }]
  end

  def gracefully_get_attachments
    get_attachments(mail).flatten.compact
  rescue => e # Protect process to work with spam emails (see test/fixtures/mail15.box)
    raise e if (fail_count ||= 0).positive?

    (fail_count += 1) && retry
  end

  def get_attachments(part, attachments: [], parent: nil)
    return part.parts.map { |p| get_attachments(p, attachments:, parent: part) } if part.parts.any?
    return [] if skip_attachments?(part, parent)

    Channel::EmailParser::AttachmentParser.new(part, attachments).parse
  end

  def skip_attachments?(part, parent)
    return true if part_in_visible_parts?(part)
    return true if part_is_auto_generated_text_body?(part)
    return true if part_is_plain_text_body?(part)
    return true if part_is_html_alternative_in_mixed?(part, parent)
    return true if part_is_html_body_of_singlepart_email?(part)

    false
  end

  # https://github.com/zammad/zammad/issues/5905
  def part_is_auto_generated_text_body?(part)
    return false if part.attachment?

    part.content_type.blank?
  end

  def part_is_plain_text_body?(part)
    return false if part.attachment?

    plain_text_part?(part)
  end

  def part_is_html_alternative_in_mixed?(part, parent)
    return false if part.attachment?

    mixed_part?(parent) && html_part?(part)
  end

  # https://github.com/zammad/zammad/issues/5992
  # For a non-multipart text/html email the top-level mail object IS the body,
  # but mail.html_part returns nil (Mail gem only searches sub-parts). Without
  # this guard the part falls through to AttachmentParser and a spurious
  # "document.html" attachment is created alongside the correct article body.
  def part_is_html_body_of_singlepart_email?(part)
    return false if part.attachment?
    return false if mail.multipart?

    html_part?(part)
  end

  def mixed_part?(part)
    part&.content_type&.start_with?('multipart/mixed')
  end

  def plain_text_part?(part)
    part.content_type&.start_with?('text/plain')
  end

  def html_part?(part)
    part.content_type&.start_with?('text/html')
  end

  def part_in_visible_parts?(part)
    [mail.text_part, mail.html_part].any? { |subpart| subpart&.body&.encoded == part.body.encoded }
  end
end
