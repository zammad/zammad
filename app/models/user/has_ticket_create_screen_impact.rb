# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class User
  module HasTicketCreateScreenImpact
    extend ActiveSupport::Concern

    def push_ticket_create_screen?
      return true if destroyed?
      return false if %w[id login firstname lastname preferences active].none? do |attribute|
        saved_change_to_attribute?(attribute)
      end

      permissions?('ticket.agent')
    end
  end
end
