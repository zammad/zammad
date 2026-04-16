# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Ticket::SearchIndex
  extend ActiveSupport::Concern

  def search_index_attribute_lookup(include_references: true)
    attributes = super
    return if !attributes

    # hook number
    attributes['hook_number'] = "#{Setting.get('ticket_hook')}#{number}"

    # collect article data
    # add tags
    attributes['tags'] = tag_list

    # mentions
    attributes['mention_user_ids'] = mentions.pluck(:user_id)

    # checklists
    if checklist
      attributes['checklist'] = checklist.search_index_attribute_lookup(include_references: false)
    end

    # collect article data
    attributes['article'] = []

    # current payload size
    total_size_current = attributes.to_json.bytesize

    Ticket::Article.where(ticket_id: id).limit(1000).find_each(batch_size: 50).each do |article|

      # lookup attributes of ref. objects (normally name and note)
      article_attributes = search_index_article_attributes(article)

      article_attributes_payload_size = article_attributes.to_json.bytesize

      next if SearchIndexBackend.payload_too_big?(total_size_current + article_attributes_payload_size)

      # add body size to totel payload size
      total_size_current += article_attributes_payload_size

      # lookup attachments
      article_attributes['attachment'] = article.search_index_attachments_lookup(total_size_current)

      total_size_current += article_attributes['attachment'].map { it['_size'] }.sum

      attributes['article'].push article_attributes
    end

    attributes
  end

  private

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

    if article_attributes['detected_language']
      article_attributes['detected_language_name'] = LanguageDetectionHelper.display_value(article_attributes['detected_language'])
    end

    article_attributes
  end
end
