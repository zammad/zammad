# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Attributes::TicketPriority < CoreWorkflow::Attributes::Base
  def values
    @values ||= begin
      Ticket::Priority.where(active: true).each_with_object([]) do |priority, priority_ids|
        @attributes.assets = priority.assets(@attributes.assets)
        priority_ids.push priority.id
      end
    end
  end
end
