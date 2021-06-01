# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sla
  module Assets
    extend ActiveSupport::Concern

=begin

get all assets / related models for this sla

  sla = Sla.find(123)
  result = sla.assets(assets_if_exists)

returns

  result = {
    :slas => {
      123  => sla_model_123,
      1234 => sla_model_1234,
    }
  }

=end

    def assets (data)

      app_model_sla = Sla.to_app_model

      if !data[ app_model_sla ]
        data[ app_model_sla ] = {}
      end
      return data if data[ app_model_sla ][ id ]

      data[ app_model_sla ][ id ] = attributes_with_association_ids
      data = assets_of_selector('condition', data)
      if calendar_id
        calendar = Calendar.lookup(id: calendar_id)
        if calendar
          data = calendar.assets(data)
        end
      end

      app_model_user = User.to_app_model
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
