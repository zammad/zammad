# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module Organization::Assets

=begin

get all assets / related models for this organization

  organization = Organization.find(123)
  result = organization.assets( assets_if_exists )

returns

  result = {
    :organizations => {
      123  => organization_model_123,
      1234 => organization_model_1234,
    }
  }

=end

  def assets (data)

    if !data[ Organization.to_app_model ]
      data[ Organization.to_app_model ] = {}
    end
    if !data[ User.to_app_model ]
      data[ User.to_app_model ] = {}
    end
    if !data[ Organization.to_app_model ][ self.id ]
      data[ Organization.to_app_model ][ self.id ] = self.attributes_with_associations
      if data[ Organization.to_app_model ][ self.id ]['member_ids']
        data[ Organization.to_app_model ][ self.id ]['member_ids'].each {|user_id|
          if !data[ User.to_app_model ][ user_id ]
            user = User.find( user_id )
            data = user.assets( data )
          end
        }
      end
    end
    ['created_by_id', 'updated_by_id'].each {|item|
      if self[ item ]
        if !data[ User.to_app_model ][ self[ item ] ]
          user = User.find( self[ item ] )
          data = user.assets( data )
        end
      end
    }
    data
  end

end