# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Template
  module Assets
    extend ActiveSupport::Concern

    def assets(data)
      return data if assets_added_to?(data)

      app_model = Template.to_app_model

      if !data[ app_model ]
        data[ app_model ] = {}
      end
      return data if data[ app_model ][ id ]

      data[ app_model ][ id ] = attributes_with_association_ids
      assets_content(data)

      data
    end

    def assets_content(data)
      return if options.blank?

      assets_user(data)
      assets_state(data)
      assets_priority(data)
      assets_group(data)
    end

    def assets_user(data)
      User.find_by(id: options[:owner_id])&.assets(data)
      User.find_by(id: options[:customer_id])&.assets(data)
    end

    def assets_state(data)
      Ticket::State.find_by(id: options[:state_id])&.assets(data)
    end

    def assets_priority(data)
      Ticket::Priority.find_by(id: options[:priority_id])&.assets(data)
    end

    def assets_group(data)
      Group.find_by(id: options[:group_id])&.assets(data)
    end
  end
end
