# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Organization
  module Assets

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

      if !data[ Organization.to_app_model ]
        data[ Organization.to_app_model ] = {}
      end
      if !data[ User.to_app_model ]
        data[ User.to_app_model ] = {}
      end
      if !data[ Organization.to_app_model ][ id ]
        local_attributes = attributes

        # set temp. current attributes to assets pool to prevent
        # loops, will be updated with lookup attributes later
        data[ Organization.to_app_model ][ id ] = local_attributes

        # get organizations
        key = "Organization::member_ids::#{id}"
        local_member_ids = Cache.get(key)
        if !local_member_ids
          local_member_ids = member_ids
          Cache.write(key, local_member_ids)
        end
        local_attributes['member_ids'] = local_member_ids
        if local_member_ids
          local_member_ids.each {|local_user_id|
            next if data[ User.to_app_model ][ local_user_id ]
            user = User.lookup(id: local_user_id)
            next if !user
            data = user.assets(data)
          }
        end

        data[ Organization.to_app_model ][ id ] = local_attributes
      end
      %w(created_by_id updated_by_id).each {|local_user_id|
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
