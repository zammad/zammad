# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Organization
  module Assets
    extend ActiveSupport::Concern

=begin

get all assets / related models for this organization

  organization = Organization.find(123)
  result = organization.assets(assets_if_exists)

returns

  result = {
    :organizations => {
      123  => organization_model_123,
      1234 => organization_model_1234,
    }
  }

=end

    def assets(data)

      app_model_organization = Organization.to_app_model

      if !data[ app_model_organization ]
        data[ app_model_organization ] = {}
      end
      return data if data[ app_model_organization ][ id ]

      local_attributes = attributes_with_association_ids

      # set temp. current attributes to assets pool to prevent
      # loops, will be updated with lookup attributes later
      data[ app_model_organization ][ id ] = local_attributes

      # support primary and secodary members
      local_attributes['member_ids'] = Array(local_attributes['member_ids']) | Array(local_attributes['secondary_member_ids'])

      app_model_user = User.to_app_model
      if local_attributes['member_ids'].present?

        # only provide assets for the first 10 organization users
        # rest will be loaded optionally by the frontend
        local_attributes['member_ids'] = local_attributes['member_ids'].sort
        local_attributes['member_ids'][0, 10].each do |local_user_id|
          next if data[ app_model_user ] && data[ app_model_user ][ local_user_id ]

          user = User.lookup(id: local_user_id)
          next if !user

          data = user.assets(data)
        end
      end

      data[ app_model_organization ][ id ] = local_attributes

      if !data[ app_model_user ]
        data[ app_model_user ] = {}
      end
      data
    end

    def filter_unauthorized_attributes(attributes)
      return super if UserInfo.assets.blank? || UserInfo.assets.agent?

      attributes = super
      attributes.slice('id', 'name', 'active')
    end
  end
end
