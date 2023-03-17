# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Attributes::TicketPriority < CoreWorkflow::Attributes::Base
  def values
    @values ||= begin
      Ticket::Priority.where(active: true).each_with_object([]) do |priority, priority_ids|
        priority_ids.push priority.id
        assets(priority)
      end
    end
  end

  def assets(priority)
    return if @attributes.assets == false
    return if @attributes.assets[Ticket::Priority.to_app_model] && @attributes.assets[Ticket::Priority.to_app_model][priority.id]

    @attributes.assets = priority.assets(@attributes.assets)
  end
end
