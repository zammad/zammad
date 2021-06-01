# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Ticket::Article::Assets
  extend ActiveSupport::Concern

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

    app_model_article = Ticket::Article.to_app_model

    if !data[ app_model_article ]
      data[ app_model_article ] = {}
    end
    return data if data[ app_model_article ][ id ]

    app_model_ticket = Ticket.to_app_model
    app_model_user = User.to_app_model

    if !data[ app_model_ticket ]
      data[ app_model_ticket ] = {}
    end
    if !data[ app_model_ticket ][ ticket_id ]
      ticket = Ticket.lookup(id: ticket_id)
      if ticket
        data = ticket.assets(data)
      end
    end

    data[ app_model_article ][ id ] = attributes_with_association_ids

    %w[created_by_id updated_by_id origin_by_id].each do |local_user_id|
      next if !self[ local_user_id ]
      next if data[ app_model_user ] && data[ app_model_user ][ self[ local_user_id ] ]

      user = User.lookup(id: self[ local_user_id ])
      next if !user

      data = user.assets(data)
    end
    data
  end
end
