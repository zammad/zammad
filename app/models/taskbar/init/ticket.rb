# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Taskbar::Init::Ticket < Taskbar::Init::Backend
  def data(result)
    result[:ticket_all] = TicketPolicy::ReadScope
      .new(current_user, Ticket.where(id: ticket_ids))
      .resolve
      .each_with_object({}) do |elem, memo|
        memo[elem.id] = Ticket::AssetsAll
          .new(current_user, elem)
          .all_assets(result[:assets])
          .except(:assets)
      end

    result
  end
end
