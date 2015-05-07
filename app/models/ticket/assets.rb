# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
# rubocop:disable ClassAndModuleChildren
module Ticket::Assets

=begin

get all assets / related models for this ticket

  ticket = Ticket.find(123)
  result = ticket.assets( assets_if_exists )

returns

  result = {
    :users => {
      123  => user_model_123,
      1234 => user_model_1234,
    }
    :tickets => [ ticket_model1 ]
  }

=end

  def assets (data)

    if !data[ Ticket.to_app_model ]
      data[ Ticket.to_app_model ] = {}
    end
    if !data[ Ticket.to_app_model ][ self.id ]
      data[ Ticket.to_app_model ][ self.id ] = self.attributes_with_associations
    end
    %w(created_by_id updated_by_id owner_id customer_id).each {|item|
      next if !self[ item ]
      if !data[ User.to_app_model ] || !data[ User.to_app_model ][ self[ item ] ]
        user = User.lookup( id: self[ item ] )
        data = user.assets( data )
      end
    }
    data
  end
end
