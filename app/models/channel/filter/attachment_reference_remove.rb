# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::AttachmentReferenceRemove

  LOCAL_ATTACHMENT_PATH_REGEXP = %r{\A/?api/v1/(?:attachments|ticket_attachment)/}i

  def self.run(_channel, mail, _transaction_params)
    return if mail[:body].blank?
    return if mail[:content_type] != 'text/html'

    removed = false

    scrubber = Loofah::Scrubber.new do |node|
      next if node.name != 'img'
      next if !local_attachment_reference?(node['src'])

      node.remove
      removed = true
    end

    body = Loofah.scrub_fragment(mail[:body], scrubber).to_s
    return if !removed

    mail[:body] = body

    true
  end

  def self.local_attachment_reference?(src)
    return false if src.blank?

    LOCAL_ATTACHMENT_PATH_REGEXP.match?(cleanup_source(src))
  end

  def self.cleanup_source(src)
    CGI.unescape(src)
       .utf8_encode(fallback: :read_as_sanitized_binary)
       .tr('\\', '/')
       .gsub(%r{[[:space:]]}, '')
  end
end
