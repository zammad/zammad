# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Attributes::TicketPriority < CoreWorkflow::Attributes::Base
  def values
    @values ||= begin
      Ticket::Priority.where(active: true).each_with_object([]) do |priority, priority_ids|
        priority_ids.push priority.id
      end
    end
  end

  def default_value
    @default_value ||= Ticket::Priority.find_by(default_create: true).try(:id)&.to_s
  end
end
