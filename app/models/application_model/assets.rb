# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::Assets

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

  def assets (data = {})

    if !data[ self.class.to_app_model ]
      data[ self.class.to_app_model ] = {}
    end
    if !data[ self.class.to_app_model ][ self.id ]
      data[ self.class.to_app_model ][ self.id ] = self.attributes
    end

    return data if !self['created_by_id'] && !self['updated_by_id']
    if !data[ User.to_app_model ]
      data[ User.to_app_model ] = {}
    end
    if self['created_by_id']
      if !data[ User.to_app_model ][ self['created_by_id'] ]
        data[ User.to_app_model ][ self['created_by_id'] ] = User.user_data_full( self['created_by_id'] )
      end
    end
    if self['updated_by_id']
      if !data[ User.to_app_model ][ self['updated_by_id'] ]
        data[ User.to_app_model ][ self['updated_by_id'] ] = User.user_data_full( self['updated_by_id'] )
      end
    end
    data
  end

end
