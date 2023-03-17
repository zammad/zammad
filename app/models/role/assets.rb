# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
      data
    end

    def filter_unauthorized_attributes(attributes)
      return super if UserInfo.assets.blank? || UserInfo.assets.agent?

      attributes = super
      attributes['name'] = "Role_#{id}"
      attributes.slice('id', 'name', 'group_ids', 'permission_ids', 'active')
    end
  end
end
