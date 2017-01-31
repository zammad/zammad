# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

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

    def assets(data)

      app_model_overview = Overview.to_app_model
      app_model_user = User.to_app_model

      if !data[ app_model_overview ]
        data[ app_model_overview ] = {}
      end
      if !data[ app_model_user ]
        data[ app_model_user ] = {}
      end
      if !data[ app_model_overview ][ id ]
        data[ app_model_overview ][ id ] = attributes_with_association_ids
        if user_ids
          user_ids.each { |local_user_id|
            next if data[ app_model_user ][ local_user_id ]
            user = User.lookup(id: local_user_id)
            next if !user
            data = user.assets(data)
          }
        end

        data = assets_of_selector('condition', data)

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
