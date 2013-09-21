# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module User::Assets

=begin

get all assets / related models for this user

  user = User.find(123)
  result = user.assets( assets_if_exists )

returns

  result = {
    :users => {
      123  => user_model_123,
      1234 => user_model_1234,
    }
  }

=end

  def assets (data)

    if !data[ User.to_online_model.to_sym ]
      data[ User.to_online_model.to_sym ] = {}
    end
    if !data[ User.to_online_model.to_sym ][ self.id ]
      data[ User.to_online_model.to_sym ][ self.id ] = User.user_data_full( self.id )
    end
    data
  end

end