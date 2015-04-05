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

    # for performance reasons, Model.search_index_reload will only collect if of object
    # get whole data here
    ticket = self.class.find(self.id)

    # remove ignored attributes
    attributes = ticket.attributes
    ignore_attributes.each {|key, value|
      next if value != true
      attributes.delete( key.to_s )
    }

    # add tags
    tags = Tag.tag_list( :object=> 'Ticket', :o_id => self.id )
    if tags && !tags.empty?
      attributes[:tag] = tags
    end

    # lookup attributes of ref. objects (normally name and note)
    attributes = search_index_attribute_lookup( attributes, ticket )

    # list ignored file extentions
    ignore_attachments = [ '.png', '.jpg', '.jpeg', '.mpeg', '.mov' ]

    # collect article data
    articles = Ticket::Article.where( :ticket_id => self.id )
    attributes['articles_all'] = []
    articles.each {|article|
      article_attributes = article.attributes

      # remove note needed attributes
      ignore = ['created_by_id', 'updated_by_id', 'updated_at', 'references', 'message_id_md5', 'message_id', 'in_reply_to', 'ticket_id']
      ignore.each {|attribute|
        article_attributes.delete( attribute )
      }

      # lookup attributes of ref. objects (normally name and note)
      article_attributes = search_index_attribute_lookup( article_attributes, article )

      # index raw text body
      if article_attributes['content_type'] && article_attributes['content_type'] == 'text/html' && article_attributes['body']
        article_attributes['body'] = article_attributes['body'].html2text
      end

      # lookup attachments
      article.attachments.each {|attachment|
        if !attributes['attachments']
          attributes['attachments'] = []
        end

        # check file size

        # check ignored files
        if attachment.filename
          filename_extention = attachment.filename.downcase
          filename_extention.gsub!(/^.*(\..+?)$/, "\\1")
          if !ignore_attachments.include?( filename_extention.downcase )
            data = {
              "_name"   => attachment.filename,
              "content" => Base64.encode64( attachment.content )
            }
            attributes['attachments'].push data
          end
        end
      }
      attributes['articles_all'].push article_attributes
    }

    return if !attributes
    SearchIndexBackend.add(self.class.to_s, attributes)
  end

end