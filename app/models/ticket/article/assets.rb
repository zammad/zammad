# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module Ticket::Article::Assets

=begin

get all assets / related models for this article

  article = Ticket::Article.find(123)
  result = article.assets( assets_if_exists )

returns

  result = {
    :users => {
      123  => user_model_123,
      1234 => user_model_1234,
    }
    :article => [ article_model1 ],
  }

=end

  def assets (data)

    if !data[:ticket_article]
      data[:ticket_article] = {}
    end
    if !data[:ticket_article][ self.id ]
      data[:ticket_article][ self.id ] = self.attributes

      # add attachment list to article
      data[:ticket_article][ self.id ]['attachments'] = Store.list( :object => 'Ticket::Article', :o_id => self.id )
    end

    if !data[:users]
      data[:users] = {}
    end
    if !data[:users][ self['created_by_id'] ]
      data[:users][ self['created_by_id'] ] = User.user_data_full( self['created_by_id'] )
    end
    if !data[:users][ self['updated_by_id'] ]
      data[:users][ self['updated_by_id'] ] = User.user_data_full( self['updated_by_id'] )
    end
    data
  end

end