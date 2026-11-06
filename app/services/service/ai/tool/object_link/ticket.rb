# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Tool::ObjectLink::Ticket < Service::AI::Tool::ObjectLink
  page 'Ticket', 'ticket/zoom/%{id}'

  def self.label_of(row, **)
    "Ticket #{row['number']} (ID #{row['id']})"
  end
end
