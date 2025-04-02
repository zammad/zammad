# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Checklist::Item
  module Assets
    extend ActiveSupport::Concern

    def assets(data)
      app_model = self.class.to_app_model

      if !data[ app_model ]
        data[ app_model ] = {}
      end
      return data if data[ app_model ][ id ]

      data[ app_model ][ id ] = attributes_with_association_ids

      ticket&.assets(data) if ticket&.authorized_asset?
      checklist.assets(data)

      data
    end
  end
end
