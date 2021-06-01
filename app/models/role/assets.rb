# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Role
  module Assets
    extend ActiveSupport::Concern

=begin

get all assets / related models for this roles

  role = Role.find(123)
  result = role.assets(assets_if_exists)

returns

  result = {
    :Role => {
      123  => role_model_123,
      1234 => role_model_1234,
    }
  }

=end

    def assets(data)

      app_model = self.class.to_app_model

      if !data[ app_model ]
        data[ app_model ] = {}
      end
      return data if data[ app_model ][ id ]

      local_attributes = attributes_with_association_ids

      # set temp. current attributes to assets pool to prevent
      # loops, will be updated with lookup attributes later
      data[ app_model ][ id ] = local_attributes

      local_attributes['group_ids'].each_key do |group_id|
        next if data[:Group] && data[:Group][group_id]

        group = Group.lookup(id: group_id)
        next if !group

        data = group.assets(data)
      end

      return data if !self['created_by_id'] && !self['updated_by_id']

      app_model_user = User.to_app_model
      %w[created_by_id updated_by_id].each do |local_user_id|
        next if !self[ local_user_id ]
        next if data[ app_model_user ] && data[ app_model_user ][ self[ local_user_id ] ]

        user = User.lookup(id: self[ local_user_id ])
        next if !user

        data = user.assets(data)
      end
      data
    end
  end
end
