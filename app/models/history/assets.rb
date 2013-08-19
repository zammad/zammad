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

    if !data[:users]
      data[:users] = {}
    end
    if !data[:users][ self['created_by_id'] ]
      data[:users][ self['created_by_id'] ] = User.user_data_full( self['created_by_id'] )
    end

    # fetch meta relations
    if !data[:history_object]
      data[:history_object] = History::Object.all()
    end
    if !data[:history_type]
      data[:history_type] = History::Type.all()
    end
    if !data[:history_attribute]
      data[:history_attribute] = History::Attribute.all()
    end

    data
  end

end