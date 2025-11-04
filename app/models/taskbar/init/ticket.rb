# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Taskbar::Init::Ticket < Taskbar::Init::Backend
  def data(result)
    TicketPolicy::ReadScope
      .new(current_user, Ticket.where(id: ticket_ids))
      .resolve
      .each_with_object({}) do |elem, _memo|
        elem.assets(result[:assets])
      end
  end
end
