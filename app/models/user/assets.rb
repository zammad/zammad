# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

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

    if !data[ User.to_app_model ]
      data[ User.to_app_model ] = {}
    end
    if !data[ User.to_app_model ][ self.id ]
      data[ User.to_app_model ][ self.id ] = User.user_data_full( self.id )
    end
    if self.organization_id
      if !data[ Organization.to_app_model ]
        data[ Organization.to_app_model ] = {}
      end
      if !data[ Organization.to_app_model ][ self.organization_id ]
        data[ Organization.to_app_model ][ self.organization_id ] = Organization.find( self.organization_id )
      end
    end
    if !data[ User.to_app_model ][ self.created_by_id ]
      data[ User.to_app_model ][ self.created_by_id ] = User.user_data_full( self.created_by_id )
    end
    if !data[ User.to_app_model ][ self.updated_by_id ]
      data[ User.to_app_model ][ self.updated_by_id ] = User.user_data_full( self.updated_by_id )
    end
    data
  end

end
