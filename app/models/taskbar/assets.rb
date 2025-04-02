# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Taskbar
  module Assets
    extend ActiveSupport::Concern

    def assets(data)
      return data if assets_added_to?(data)

      app_model = Taskbar.to_app_model

      if !data[ app_model ]
        data[ app_model ] = {}
      end
      return data if data[ app_model ][ id ]

      data[ app_model ][ id ] = attributes_with_association_ids
      assets_content(data)

      data
    end

    def assets_content(data)
      return if state.blank?
      return if !key.starts_with?('TicketCreateScreen')

      assets_user(data)
    end

    def assets_user(data)
      User.find_by(id: state[:owner_id])&.assets(data)
      User.find_by(id: state[:customer_id])&.assets(data)
    end
  end
end
