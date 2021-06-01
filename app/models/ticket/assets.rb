# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Ticket::Assets
  extend ActiveSupport::Concern

=begin

get all assets / related models for this ticket

  ticket = Ticket.find(123)
  result = ticket.assets(assets_if_exists)

returns

  result = {
    users: {
      123: user_model_123,
      1234: user_model_1234,
    },
    tickets: [ ticket_model1 ]
  }

=end

  def assets(data)

    app_model_ticket = Ticket.to_app_model

    if !data[ app_model_ticket ]
      data[ app_model_ticket ] = {}
    end
    return data if data[ app_model_ticket ][ id ]

    data[ app_model_ticket ][ id ] = attributes_with_association_ids

    app_model_user = User.to_app_model

    %w[created_by_id updated_by_id owner_id customer_id].each do |local_user_id|
      next if !self[ local_user_id ]
      next if data[ app_model_user ] && data[ app_model_user ][ self[ local_user_id ] ]

      user = User.lookup(id: self[ local_user_id ])
      next if !user

      data = user.assets(data)
    end
    data
  end
end
