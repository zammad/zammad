# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Trigger
  module Assets
    extend ActiveSupport::Concern

=begin

get all assets / related models for this trigger

  trigger = Trigger.find(123)
  result = trigger.assets(assets_if_exists)

returns

  result = {
    :triggers => {
      123  => trigger_model_123,
      1234 => trigger_model_1234,
    }
  }

=end

    def assets(data)

      app_model_overview = Trigger.to_app_model
      app_model_user = User.to_app_model

      if !data[ app_model_overview ]
        data[ app_model_overview ] = {}
      end
      if !data[ app_model_user ]
        data[ app_model_user ] = {}
      end
      if !data[ app_model_overview ][ id ]
        data[ app_model_overview ][ id ] = attributes_with_association_ids
        data = assets_of_selector('condition', data)
        data = assets_of_selector('perform', data)
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
