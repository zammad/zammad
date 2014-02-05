# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module Ticket::SearchIndex

=begin

build and send data for search index to backend

  ticket = Ticket.find(123)
  result = ticket.search_index_update_backend

returns

  result = true # false

=end

  def search_index_update_backend
    return if !self.class.search_index_support_config

    # default ignored attributes
    ignore_attributes = {
      :created_by_id            => true,
      :updated_by_id            => true,
      :active                   => true,
    }
    if self.class.search_index_support_config[:ignore_attributes]
      self.class.search_index_support_config[:ignore_attributes].each {|key, value|
        ignore_attributes[key] = value
      }
    end

    attributes = self.attributes
    ignore_attributes.each {|key, value|
      next if value != true
      attributes.delete( key.to_s )
    }

    # add tags
    tags = Tag.tag_list( :object=> 'Ticket', :o_id => self.id )
    if tags && !tags.empty?
      attributes[:tag] = tags
    end

    attributes = search_index_attribute_lookup( attributes, self )

    # add article data
    articles = Ticket::Article.where( :ticket_id => self.id )
    attributes['articles_all'] = []
    attributes['articles_external'] = []
    articles.each {|article|
      article_attributes = article.attributes
      article_attributes.delete('created_by_id')
      article_attributes.delete('updated_by_id')
      article_attributes.delete('updated_at')
      article_attributes.delete('references')
      article_attributes.delete('message_id_md5')
      article_attributes.delete('message_id')
      article_attributes.delete('in_reply_to')
      article_attributes.delete('ticket_id')
      article_attributes = search_index_attribute_lookup( article_attributes, article )

      # lookup attachments
      article.attachments.each {|attachment|
        if !article_attributes['attachments']
          article_attributes['attachments'] = []
        end
        data = {
          "_name"   => attachment.filename,
          "content" => Base64.encode64( attachment.store_file.data )
        }
        article_attributes['attachments'].push data
      }
      attributes['articles_all'].push article_attributes
      if !article.internal
        attributes['articles_external'].push article_attributes
      end
    }

    return if !attributes
    SearchIndexBackend.add(self.class.to_s, attributes)
  end

end
