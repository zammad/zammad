# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Checklist::Item
  module Assets
    extend ActiveSupport::Concern

    def assets(...)
      data = super

      checklist.assets(data)
      ticket&.assets(data) if ticket&.authorized_asset?

      add_referencing_ticket_assets(data)

      data
    end

    private

    def add_referencing_ticket_assets(data)
      return if !ticket

      if !checklist.ticket.authorized_asset?
        data[self.class.to_app_model][id]['ticket_inaccessible'] = true
        return
      end

      ticket.assets(data)
    end
  end
end
