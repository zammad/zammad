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

    if !data[ User.to_online_model.to_sym ]
      data[ User.to_online_model.to_sym ] = {}
    end
    if !data[ User.to_online_model.to_sym ][ self['created_by_id'] ]
      data[ User.to_online_model.to_sym ][ self['created_by_id'] ] = User.user_data_full( self['created_by_id'] )
    end

    # fetch meta relations
    if !data[ History::Object.to_online_model.to_sym ]
      data[ History::Object.to_online_model.to_sym ] = History::Object.all()
    end
    if !data[ History::Type.to_online_model.to_sym ]
      data[ History::Type.to_online_model.to_sym ] = History::Type.all()
    end
    if !data[ History::Attribute.to_online_model.to_sym ]
      data[ History::Attribute.to_online_model.to_sym ] = History::Attribute.all()
    end

    data
  end

end