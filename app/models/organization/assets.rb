# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Organization
  module Assets

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
      app_model_user = User.to_app_model

      if !data[ app_model_organization ]
        data[ app_model_organization ] = {}
      end
      if !data[ app_model_user ]
        data[ app_model_user ] = {}
      end
      if !data[ app_model_organization ][ id ]
        local_attributes = attributes

        # set temp. current attributes to assets pool to prevent
        # loops, will be updated with lookup attributes later
        data[ app_model_organization ][ id ] = local_attributes

        # get organizations
        key = "Organization::member_ids::#{id}"
        local_member_ids = Cache.get(key)
        if !local_member_ids
          local_member_ids = member_ids
          Cache.write(key, local_member_ids)
        end
        local_attributes['member_ids'] = local_member_ids
        if local_member_ids
          local_member_ids.each { |local_user_id|
            next if data[ app_model_user ][ local_user_id ]
            user = User.lookup(id: local_user_id)
            next if !user
            data = user.assets(data)
          }
        end

        data[ app_model_organization ][ id ] = local_attributes
      end
      %w(created_by_id updated_by_id).each { |local_user_id|
        next if !self[ local_user_id ]
        next if data[ app_model_user ][ self[ local_user_id ] ]
        user = User.lookup(id: self[ local_user_id ])
        next if !user
        data = user.assets(data)
      }
      data
    end
  end
end
