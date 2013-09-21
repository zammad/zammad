# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

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

    if !data[ Ticket.to_online_model.to_sym ]
      data[ Ticket.to_online_model.to_sym ] = {}
    end
    if !data[ Ticket.to_online_model.to_sym ][ self.id ]
      data[ Ticket.to_online_model.to_sym ][ self.id ] = self.attributes
    end

    if !data[ User.to_online_model.to_sym ]
      data[ User.to_online_model.to_sym ] = {}
    end
    if !data[ User.to_online_model.to_sym ][ self['owner_id'] ]
      data[ User.to_online_model.to_sym ][ self['owner_id'] ] = User.user_data_full( self['owner_id'] )
    end
    if !data[ User.to_online_model.to_sym ][ self['customer_id'] ]
      data[ User.to_online_model.to_sym ][ self['customer_id'] ] = User.user_data_full( self['customer_id'] )
    end
    if !data[ User.to_online_model.to_sym ][ self['created_by_id'] ]
      data[ User.to_online_model.to_sym ][ self['created_by_id'] ] = User.user_data_full( self['created_by_id'] )
    end
    if !data[ User.to_online_model.to_sym ][ self['updated_by_id'] ]
      data[ User.to_online_model.to_sym ][ self['updated_by_id'] ] = User.user_data_full( self['updated_by_id'] )
    end
    data
  end

end