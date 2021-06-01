# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

      app_model_user = User.to_app_model
      if local_attributes['member_ids'].present?

        # feature used for different purpose; do limit references
        if local_attributes['member_ids'].count > 100
          local_attributes['member_ids'] = local_attributes['member_ids'].sort[0, 100]
        end
        local_attributes['member_ids'].each do |local_user_id|
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

      %w[created_by_id updated_by_id].each do |local_user_id|
        next if !self[ local_user_id ]
        next if data[ app_model_user ][ self[ local_user_id ] ]

        user = User.lookup(id: self[ local_user_id ])
        next if !user

        data = user.assets(data)
      end
      data
    end
  end
end
