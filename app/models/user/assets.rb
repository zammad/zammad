# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class User
  module Assets
    extend ActiveSupport::Concern

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
      return data if assets_added_to?(data)

      app_model = User.to_app_model

      if !data[ app_model ]
        data[ app_model ] = {}
      end
      return data if data[ app_model ][ id ]

      local_attributes = attributes_with_association_ids

      # do not transfer crypted pw
      local_attributes.delete('password')

      # set temp. current attributes to assets pool to prevent
      # loops, will be updated with lookup attributes later
      data[ app_model ][ id ] = local_attributes

      # get linked accounts
      local_attributes['accounts'] = {}
      key = "User::authorizations::#{id}"
      local_accounts = Cache.read(key)
      if !local_accounts
        local_accounts = {}
        authorizations = self.authorizations()
        authorizations.each do |authorization|
          local_accounts[authorization.provider] = {
            uid:      authorization[:uid],
            username: authorization[:username]
          }
        end
        Cache.write(key, local_accounts)
      end
      local_attributes['accounts'] = local_accounts

      # get roles
      local_attributes['role_ids']&.each do |role_id|
        next if data[:Role] && data[:Role][role_id]

        role = Role.lookup(id: role_id)
        next if !role

        data = role.assets(data)
      end

      # get groups
      local_attributes['group_ids']&.each do |group_id, _access|
        next if data[:Group] && data[:Group][group_id]

        group = Group.lookup(id: group_id)
        next if !group

        data = group.assets(data)
      end

      # get organizations
      local_attributes['organization_ids']&.each do |organization_id|
        next if data[:Organization] && data[:Organization][organization_id]

        organization = Organization.lookup(id: organization_id)
        next if !organization

        data = organization.assets(data)
      end

      data[ app_model ][ id ] = local_attributes

      # add organization
      if self.organization_id
        if !data[:Organization] || !data[:Organization][self.organization_id] # rubocop:disable Style/SoleNestedConditional
          organization = Organization.lookup(id: self.organization_id)
          if organization
            data = organization.assets(data)
          end
        end
      end
      %w[created_by_id updated_by_id].each do |local_user_id|
        next if !self[ local_user_id ]
        next if data[ app_model ][ self[ local_user_id ] ]

        user = User.lookup(id: self[ local_user_id ])
        next if !user

        data = user.assets(data)
      end
      data
    end
  end
end
