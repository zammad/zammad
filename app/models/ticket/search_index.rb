# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module Ticket::SearchIndex
  extend ActiveSupport::Concern

=begin

lookup name of ref. objects

  ticket = Ticket.find(123)
  result = ticket.search_index_attribute_lookup

returns

  attributes # object with lookup data

=end

  def search_index_attribute_lookup
    attributes = super
    return if !attributes

    # collect article data
    # add tags
    tags = tag_list
    if tags.present?
      attributes[:tags] = tags
    end

    # list ignored file extensions
    attachments_ignore = Setting.get('es_attachment_ignore') || [ '.png', '.jpg', '.jpeg', '.mpeg', '.mpg', '.mov', '.bin', '.exe' ]

    # max attachment size
    attachment_max_size_in_mb = Setting.get('es_attachment_max_size_in_mb') || 10
    attachment_total_max_size_in_kb = 314_572
    attachment_total_max_size_in_kb_current = 0

    # collect article data
    articles = Ticket::Article.where(ticket_id: id).limit(1000)
    attributes['article'] = []
    articles.each do |article|

      # lookup attributes of ref. objects (normally name and note)
      article_attributes = article.search_index_attribute_lookup

      # remove note needed attributes
      ignore = %w[message_id_md5 ticket]
      ignore.each do |attribute|
        article_attributes.delete(attribute)
      end

      # index raw text body
      if article_attributes['content_type'] && article_attributes['content_type'] == 'text/html' && article_attributes['body']
        article_attributes['body'] = article_attributes['body'].html2text
      end

      # lookup attachments
      article_attributes['attachment'] = []
      if attachment_total_max_size_in_kb_current < attachment_total_max_size_in_kb
        article.attachments.each do |attachment|

          # check file size
          next if !attachment.content
          next if attachment.content.size / 1024 > attachment_max_size_in_mb * 1024

          # check ignored files
          next if !attachment.filename

          filename_extention = attachment.filename.downcase
          filename_extention.gsub!(/^.*(\..+?)$/, '\\1')

          next if attachments_ignore.include?(filename_extention.downcase)

          attachment_total_max_size_in_kb_current += (attachment.content.size / 1024).to_i
          next if attachment_total_max_size_in_kb_current > attachment_total_max_size_in_kb

          data = {
            '_name'    => attachment.filename,
            '_content' => Base64.encode64(attachment.content).delete("\n")
          }
          article_attributes['attachment'].push data
        end
      end
      attributes['article'].push article_attributes
    end

    attributes
  end

end
