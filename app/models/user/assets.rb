# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class User
  module Assets

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

    def assets (data)

      if !data[ User.to_app_model ]
        data[ User.to_app_model ] = {}
      end
      if !data[ User.to_app_model ][ self.id ]
        attributes = self.attributes_with_associations

        # do not transfer crypted pw
        attributes['password'] = ''

        # get linked accounts
        attributes['accounts'] = {}
        authorizations = self.authorizations()
        authorizations.each do |authorization|
          attributes['accounts'][authorization.provider] = {
            uid: authorization[:uid],
            username: authorization[:username]
          }
        end

        data[ User.to_app_model ][ self.id ] = attributes

        # get roles
        if attributes['role_ids']
          attributes['role_ids'].each {|role_id|
            role = Role.lookup( id: role_id )
            data = role.assets( data )
          }
        end

        # get groups
        if attributes['group_ids']
          attributes['group_ids'].each {|group_id|
            group = Group.lookup( id: group_id )
            data = group.assets( data )
          }
        end

        # get groups
        if attributes['organization_ids']
          attributes['organization_ids'].each {|organization_id|
            organization = Organization.lookup( id: organization_id )
            data = organization.assets( data )
          }
        end
      end
      if self.organization_id
        if !data[ Organization.to_app_model ] || !data[ Organization.to_app_model ][ self.organization_id ]
          organization = Organization.lookup( id: self.organization_id )
          data = organization.assets( data )
        end
      end
      ['created_by_id', 'updated_by_id'].each {|item|
        next if !self[ item ]
        if !data[ User.to_app_model ][ self[ item ] ]
          user = User.lookup( id: self[ item ] )
          data = user.assets( data )
        end
      }
      data
    end
  end
end
