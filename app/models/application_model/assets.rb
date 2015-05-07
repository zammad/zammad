# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
# rubocop:disable ClassAndModuleChildren
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
    if !data[ self.class.to_app_model ][ self.id ]
      data[ self.class.to_app_model ][ self.id ] = self.attributes_with_associations
    end

    return data if !self['created_by_id'] && !self['updated_by_id']
    %w(created_by_id updated_by_id).each {|item|
      next if !self[ item ]
      if !data[ User.to_app_model ] || !data[ User.to_app_model ][ self[ item ] ]
        user = User.lookup( id: self[ item ] )
        data = user.assets( data )
      end
    }
    data
  end
end
