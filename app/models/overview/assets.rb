# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Overview
  module Assets

=begin

get all assets / related models for this overview

  overview = Overview.find(123)
  result = overview.assets(assets_if_exists)

returns

  result = {
    :overviews => {
      123  => overview_model_123,
      1234 => overview_model_1234,
    }
  }

=end

    def assets (data)

      if !data[ Overview.to_app_model ]
        data[ Overview.to_app_model ] = {}
      end
      if !data[ User.to_app_model ]
        data[ User.to_app_model ] = {}
      end
      if !data[ Overview.to_app_model ][ id ]
        data[ Overview.to_app_model ][ id ] = attributes_with_associations
        if user_ids
          user_ids.each { |local_user_id|
            next if data[ User.to_app_model ][ local_user_id ]
            user = User.lookup(id: local_user_id)
            next if !user
            data = user.assets(data)
          }
        end

        data = assets_of_selector('condition', data)

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
