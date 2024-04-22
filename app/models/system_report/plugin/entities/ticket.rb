# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Entities::Ticket < SystemReport::Plugin
  DESCRIPTION = __('Open and closed tickets ratio (ticket counts based on state)').freeze

  def fetch
    {
      'Open'   => Ticket.where(state_id: Ticket::State.by_category(:open)).count,
      'Closed' => Ticket.where(state_id: Ticket::State.by_category(:closed)).count,
    }
  end
end
