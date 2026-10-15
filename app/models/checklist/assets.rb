# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Checklist
  module Assets
    extend ActiveSupport::Concern

    def assets(data)
      app_model = self.class.to_app_model

      if !data[ app_model ]
        data[ app_model ] = {}
      end
      return data if data[ app_model ][ id ]

      if ticket && !ticket.authorized_asset?
        data[ app_model ][ id ] = { 'id' => id, 'ticket_inaccessible' => true }
        return data
      end

      data[ app_model ][ id ] = attributes_with_association_ids

      items.each { |elem| elem.assets(data) }
      ticket.assets(data)

      data
    end
  end
end
