# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Checklist
  module Assets
    extend ActiveSupport::Concern

    def assets(data)
      app_model = self.class.to_app_model

      if !data[ app_model ]
        data[ app_model ] = {}
      end
      Rails.logger.debug [app_model, id, data[app_model]]
      return data if data[ app_model ][ id ]

      data[ app_model ][ id ] = attributes_with_association_ids
      items.map { |item| data = item.assets(data) }
      data
    end
  end
end
