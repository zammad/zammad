# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module CanCloneAttachments
  extend ActiveSupport::Concern

=begin

clone existing attachments of article to the target object

  article_parent = Ticket::Article.find(123)
  article_new = Ticket::Article.find(456)

  attached_attachments = article_parent.clone_attachments(article_new.class.name, article_new.id, only_attached_attachments: true)

  inline_attachments = article_parent.clone_attachments(article_new.class.name, article_new.id, only_inline_attachments: true)

returns

  [attachment1, attachment2, ...]

=end

  def clone_attachments(object_type, object_id, options = {})
    existing_attachments = Store.list(
      object: object_type,
      o_id:   object_id,
    )

    is_html_content = content_type.present? && content_type =~ %r{text/html}i

    attachments
      .select do |elem|
        next if elem.preferences['content-alternative'] == true

        # only_attached_attachments mode is used by apply attached attachments to forwared article
        if options[:only_attached_attachments] == true && is_html_content

          content_id = elem.preferences['Content-ID'] || elem.preferences['content_id']
          next if content_id.present? && body.present? && body.match?(%r{#{Regexp.quote(content_id)}}i)
        end

        # only_inline_attachments mode is used when quoting HTML mail with #{article.body_as_html}
        if options[:only_inline_attachments] == true
          next if !is_html_content
          next if body.blank?

          content_disposition = elem.preferences['Content-Disposition'] || elem.preferences['content_disposition']
          next if content_disposition.present? && content_disposition.exclude?('inline')

          content_id = elem.preferences['Content-ID'] || elem.preferences['content_id']
          next if content_id.blank?
          next if !body.match?(%r{#{Regexp.quote(content_id)}}i)
        end

        next if existing_attachments.any? do |existing_attachment|
          existing_attachment.filename == elem.filename && existing_attachment.size == elem.size
        end

        true
      end
      .map do |elem|
        Store.create!(
          object:      object_type,
          o_id:        object_id,
          data:        elem.content,
          filename:    elem.filename,
          preferences: elem.preferences,
        )
      end
  end

  def attach_upload_cache(form_id, source_object_name: 'UploadCache')
    attachments
      .reject(&:inline?)
      .each { |attachment| Store.remove_item(attachment.id) }

    Store
      .list(object: source_object_name, o_id: form_id)
      .reject(&:inline?)
      .map do |old_attachment|
        Store.create!(
          object:      self.class.name,
          o_id:        id,
          data:        old_attachment.content,
          filename:    old_attachment.filename,
          preferences: old_attachment.preferences,
        )
      end
  end
end
