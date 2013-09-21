# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module History::Assets

=begin

get all assets / related models for this history entry

  history = History.find(123)
  result = history.assets( assets_if_exists )

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
    if !data[ User.to_app_model ][ self['created_by_id'] ]
      data[ User.to_app_model ][ self['created_by_id'] ] = User.user_data_full( self['created_by_id'] )
    end

    # fetch meta relations
    if !data[ History::Object.to_app_model ]
      data[ History::Object.to_app_model ] = History::Object.all()
    end
    if !data[ History::Type.to_app_model ]
      data[ History::Type.to_app_model ] = History::Type.all()
    end
    if !data[ History::Attribute.to_app_model ]
      data[ History::Attribute.to_app_model ] = History::Attribute.all()
    end

    data
  end

end