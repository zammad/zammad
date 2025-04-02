# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Taskbar::Init::TicketCreate < Taskbar::Init::Backend
  def data(result)
    result[:ticket_create] = Ticket::ScreenOptions.attributes_to_change(
      view:         'ticket_create',
      screen:       'create_middle',
      current_user: current_user,
      assets:       result[:assets],
    ).except(:assets)
    result
  end
end
