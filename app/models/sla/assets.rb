# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Sla
  module Assets

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

      if !data[ Sla.to_app_model ]
        data[ Sla.to_app_model ] = {}
      end
      if !data[ User.to_app_model ]
        data[ User.to_app_model ] = {}
      end
      if !data[ Sla.to_app_model ][ id ]
        data[ Sla.to_app_model ][ id ] = attributes_with_associations
        data = assets_of_selector('condition', data)
        if calendar_id
          calendar = Calendar.lookup(id: calendar_id)
          if calendar
            data = calendar.assets(data)
          end
        end
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
