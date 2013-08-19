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

    if !data[:tickets]
      data[:tickets] = {}
    end
    if !data[:tickets][ self.id ]
      data[:tickets][ self.id ] = self.attributes
    end

    if !data[:users]
      data[:users] = {}
    end
    if !data[:users][ self['owner_id'] ]
      data[:users][ self['owner_id'] ] = User.user_data_full( self['owner_id'] )
    end
    if !data[:users][ self['customer_id'] ]
      data[:users][ self['customer_id'] ] = User.user_data_full( self['customer_id'] )
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