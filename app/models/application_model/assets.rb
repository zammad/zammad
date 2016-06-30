# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::Assets

=begin

get all assets / related models for this user

  user = User.find(123)
  result = user.assets( assets_if_exists )

returns

  result = {
    :User => {
      123  => user_model_123,
      1234 => user_model_1234,
    }
  }

=end

  def assets (data = {})

    if !data[ self.class.to_app_model ]
      data[ self.class.to_app_model ] = {}
    end
    if !data[ self.class.to_app_model ][ id ]
      data[ self.class.to_app_model ][ id ] = attributes_with_associations
    end

    return data if !self['created_by_id'] && !self['updated_by_id']
    %w(created_by_id updated_by_id).each { |local_user_id|
      next if !self[ local_user_id ]
      next if data[ User.to_app_model ] && data[ User.to_app_model ][ self[ local_user_id ] ]
      user = User.lookup(id: self[ local_user_id ])
      next if !user
      data = user.assets(data)
    }
    data
  end
end
