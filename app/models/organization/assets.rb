# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

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

    if !data[ Organization.to_online_model.to_sym ]
      data[ Organization.to_online_model.to_sym ] = {}
    end
    if !data[ User.to_online_model.to_sym ]
      data[ User.to_online_model.to_sym ] = {}
    end
    if !data[ Organization.to_online_model.to_sym ][ self.id ]
      data[ Organization.to_online_model.to_sym ][ self.id ] = self.attributes
      data[ Organization.to_online_model.to_sym ][ self.id ][:user_ids] = []
      users = User.where( :organization_id => self.id ).limit(10)
      users.each {|user|
        data[ User.to_online_model.to_sym ][ user.id ] = User.user_data_full( user.id )
        data[ Organization.to_online_model.to_sym ][ self.id ][:user_ids].push user.id
      }
    end
    data
  end

end