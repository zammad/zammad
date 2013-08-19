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

    if !data[:organizations]
      data[:organizations] = {}
    end
    if !data[:users]
      data[:users] = {}
    end
    if !data[:organizations][ self.id ]
      data[:organizations][ self.id ] = self.attributes
      data[:organizations][ self.id ][:user_ids] = []
      users = User.where( :organization_id => self.id ).limit(10)
      users.each {|user|
        data[:users][ user.id ] = User.user_data_full( user.id )
        data[:organizations][ self.id ][:user_ids].push user.id
      }
    end
    data
  end

end