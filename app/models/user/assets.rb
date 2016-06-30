# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class User
  module Assets

=begin

get all assets / related models for this user

  user = User.find(123)
  result = user.assets(assets_if_exists)

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
      if !data[ User.to_app_model ][ id ]
        local_attributes = attributes

        # do not transfer crypted pw
        local_attributes['password'] = ''

        # set temp. current attributes to assets pool to prevent
        # loops, will be updated with lookup attributes later
        data[ User.to_app_model ][ id ] = local_attributes

        # get linked accounts
        local_attributes['accounts'] = {}
        key = "User::authorizations::#{id}"
        local_accounts = Cache.get(key)
        if !local_accounts
          local_accounts = {}
          authorizations = self.authorizations()
          authorizations.each do |authorization|
            local_accounts[authorization.provider] = {
              uid: authorization[:uid],
              username: authorization[:username]
            }
          end
          Cache.write(key, local_accounts)
        end
        local_attributes['accounts'] = local_accounts

        # get roles
        key = "User::role_ids::#{id}"
        local_role_ids = Cache.get(key)
        if !local_role_ids
          local_role_ids = role_ids
          Cache.write(key, local_role_ids)
        end
        local_attributes['role_ids'] = local_role_ids
        if local_role_ids
          local_role_ids.each { |role_id|
            role = Role.lookup(id: role_id)
            data = role.assets(data)
          }
        end

        # get groups
        key = "User::group_ids::#{id}"
        local_group_ids = Cache.get(key)
        if !local_group_ids
          local_group_ids = group_ids
          Cache.write(key, local_group_ids)
        end
        local_attributes['group_ids'] = local_group_ids
        if local_group_ids
          local_group_ids.each { |group_id|
            group = Group.lookup(id: group_id)
            next if !group
            data = group.assets(data)
          }
        end

        # get organizations
        key = "User::organization_ids::#{id}"
        local_organization_ids = Cache.get(key)
        if !local_organization_ids
          local_organization_ids = organization_ids
          Cache.write(key, local_organization_ids)
        end
        local_attributes['organization_ids'] = local_organization_ids
        if local_organization_ids
          local_organization_ids.each { |organization_id|
            organization = Organization.lookup(id: organization_id)
            next if !organization
            data = organization.assets(data)
          }
        end

        data[ User.to_app_model ][ id ] = local_attributes
      end

      # add organization
      if self.organization_id
        if !data[ Organization.to_app_model ] || !data[ Organization.to_app_model ][ self.organization_id ]
          organization = Organization.lookup(id: self.organization_id)
          if organization
            data = organization.assets(data)
          end
        end
      end
      %w(created_by_id updated_by_id).each { |local_user_id|
        next if !self[ local_user_id ]
        next if data[ User.to_app_model ][ self[ local_user_id ] ]
        user = User.lookup(id: self[ local_user_id ])
        next if !user
        data = user.assets(data)
      }
      data
    end
  end
end
