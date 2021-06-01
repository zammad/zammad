# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Overview
  module Assets
    extend ActiveSupport::Concern

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

      if !data[ app_model_overview ]
        data[ app_model_overview ] = {}
      end
      return data if data[ app_model_overview ][ id ]

      app_model_user = User.to_app_model
      if !data[ app_model_user ]
        data[ app_model_user ] = {}
      end

      data[ app_model_overview ][ id ] = attributes_with_association_ids
      user_ids&.each do |local_user_id|
        next if data[ app_model_user ][ local_user_id ]

        user = User.lookup(id: local_user_id)
        next if !user

        data = user.assets(data)
      end
      data = assets_of_selector('condition', data)

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
