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
      data[ Organization.to_app_model ][ self.id ] = self.attributes
      data[ Organization.to_app_model ][ self.id ][:user_ids] = []
      users = User.where( :organization_id => self.id ).limit(10)
      users.each {|user|
        data[ User.to_app_model ][ user.id ] = User.user_data_full( user.id )
        data[ Organization.to_app_model ][ self.id ][:user_ids].push user.id
      }
    end
    data
  end

end
