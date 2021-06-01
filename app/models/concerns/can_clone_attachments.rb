# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

    is_html_content = false
    if content_type.present? && content_type =~ %r{text/html}i
      is_html_content = true
    end

    new_attachments = []
    attachments.each do |new_attachment|
      next if new_attachment.preferences['content-alternative'] == true

      # only_attached_attachments mode is used by apply attached attachments to forwared article
      if options[:only_attached_attachments] == true && is_html_content == true

        content_id = new_attachment.preferences['Content-ID'] || new_attachment.preferences['content_id']
        next if content_id.present? && body.present? && body.match?(%r{#{Regexp.quote(content_id)}}i)
      end

      # only_inline_attachments mode is used when quoting HTML mail with #{article.body_as_html}
      if options[:only_inline_attachments] == true
        next if is_html_content == false
        next if body.blank?

        content_disposition = new_attachment.preferences['Content-Disposition'] || new_attachment.preferences['content_disposition']
        next if content_disposition.present? && content_disposition !~ %r{inline}

        content_id = new_attachment.preferences['Content-ID'] || new_attachment.preferences['content_id']
        next if content_id.blank?
        next if !body.match?(%r{#{Regexp.quote(content_id)}}i)
      end

      already_added = false
      existing_attachments.each do |existing_attachment|
        next if existing_attachment.filename != new_attachment.filename || existing_attachment.size != new_attachment.size

        already_added = true
        break
      end
      next if already_added == true

      file = Store.add(
        object:      object_type,
        o_id:        object_id,
        data:        new_attachment.content,
        filename:    new_attachment.filename,
        preferences: new_attachment.preferences,
      )
      new_attachments.push file
    end

    new_attachments
  end
end
