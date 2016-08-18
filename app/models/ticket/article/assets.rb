# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module Ticket::Article::Assets

=begin

get all assets / related models for this article

  article = Ticket::Article.find(123)
  result = article.assets(assets_if_exists)

returns

  result = {
    :users => {
      123  => user_model_123,
      1234 => user_model_1234,
    }
    :article => [ article_model1 ],
  }

=end

  def assets(data)

    app_model_ticket = Ticket.to_app_model
    app_model_article = Ticket::Article.to_app_model
    app_model_user = User.to_app_model

    if !data[ app_model_ticket ]
      data[ app_model_ticket ] = {}
    end
    if !data[ app_model_ticket ][ ticket_id ]
      ticket = Ticket.lookup(id: ticket_id)
      data = ticket.assets(data)
    end

    if !data[ app_model_article ]
      data[ app_model_article ] = {}
    end
    if !data[ app_model_article ][ id ]
      data[ app_model_article ][ id ] = attributes

      # add attachment list to article
      data[ app_model_article ][ id ]['attachments'] = attachments

      if !data[ app_model_article ][ id ]['attachments'].empty?
        if data[ app_model_article ][ id ]['content_type'] =~ %r{text/html}i
          if data[ app_model_article ][ id ]['body'] =~ /<img/i

            # insert inline images with urls
            attributes = Ticket::Article.insert_urls(
              data[ app_model_article ][ id ],
              data[ app_model_article ][ id ]['attachments']
            )
            data[ app_model_article ][ id ] = attributes
          end
        end
      end
    end

    %w(created_by_id updated_by_id).each { |local_user_id|
      next if !self[ local_user_id ]
      next if data[ app_model_user ] && data[ app_model_user ][ self[ local_user_id ] ]
      user = User.lookup(id: self[ local_user_id ])
      next if !user
      data = user.assets(data)
    }
    data
  end
end
