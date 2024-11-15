# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Ticket::SearchIndex
  extend ActiveSupport::Concern

  def search_index_attribute_lookup(include_references: true)
    attributes = super
    return if !attributes

    # collect article data
    # add tags
    attributes['tags'] = tag_list

    # mentions
    attributes['mention_user_ids'] = mentions.pluck(:user_id)

    # checklists
    if checklist
      attributes['checklist'] = checklist.search_index_attribute_lookup(include_references: false)
    end

    # current payload size
    total_size_current = 0

    # collect article data
    attributes['article'] = []
    Ticket::Article.where(ticket_id: id).limit(1000).find_each(batch_size: 50).each do |article|

      # lookup attributes of ref. objects (normally name and note)
      article_attributes = search_index_article_attributes(article)

      article_attributes_payload_size = article_attributes.to_json.bytesize

      next if search_index_attribute_lookup_oversized?(total_size_current + article_attributes_payload_size)

      # add body size to totel payload size
      total_size_current += article_attributes_payload_size

      # lookup attachments
      article_attributes['attachment'] = []

      article.attachments.each do |attachment|

        next if search_index_attribute_lookup_file_ignored?(attachment)

        next if search_index_attribute_lookup_file_oversized?(attachment, total_size_current)

        next if search_index_attribute_lookup_oversized?(total_size_current + attachment.content.bytesize)

        # add attachment size to totel payload size
        total_size_current += attachment.content.bytesize

        article_attributes['attachment'].push search_index_article_attachment_attributes(attachment)
      end

      attributes['article'].push article_attributes
    end

    attributes
  end

  private

  def search_index_attribute_lookup_oversized?(total_size_current)

    # if complete payload is to high
    total_max_size_in_kb = (Setting.get('es_total_max_size_in_mb') || 300).megabyte
    return true if total_size_current >= total_max_size_in_kb

    false
  end

  def search_index_attribute_lookup_file_oversized?(attachment, total_size_current)
    return true if attachment.content.blank?

    # if attachment size is bigger as configured
    attachment_max_size = (Setting.get('es_attachment_max_size_in_mb') || 10).megabyte
    return true if attachment.content.bytesize > attachment_max_size

    # if complete size is bigger as configured
    return true if search_index_attribute_lookup_oversized?(total_size_current + attachment.content.bytesize)

    false
  end

  def search_index_attribute_lookup_file_ignored?(attachment)
    return true if attachment.filename.blank?

    filename_extention = attachment.filename.downcase
    filename_extention.gsub!(%r{^.*(\..+?)$}, '\\1')

    # list ignored file extensions
    attachments_ignore = Setting.get('es_attachment_ignore') || [ '.png', '.jpg', '.jpeg', '.mpeg', '.mpg', '.mov', '.bin', '.exe' ]

    return true if attachments_ignore.include?(filename_extention.downcase)

    false
  end

  def search_index_article_attributes(article)

    # lookup attributes of ref. objects (normally name and note)
    article_attributes = article.search_index_attribute_lookup(include_references: false)

    # remove note needed attributes
    ignore = %w[message_id_md5 ticket]
    ignore.each do |attribute|
      article_attributes.delete(attribute)
    end

    # index raw text body
    if article_attributes['content_type'] && article_attributes['content_type'] == 'text/html' && article_attributes['body']
      article_attributes['body'] = article_attributes['body'].html2text
    end

    article_attributes
  end

  def search_index_article_attachment_attributes(attachment)
    {
      'size'     => attachment.size,
      '_name'    => attachment.filename,
      '_content' => Base64.encode64(attachment.content).delete("\n"),
    }
  end

end
