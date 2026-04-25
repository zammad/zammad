# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::Ticket::TimeAccounting < FormUpdater::Updater

  def self.required_permissions
    %w[ticket.agent]
  end

  def resolve
    if meta[:initial]
      result['accounted_time_type_id'] = accounted_time_type_options
    end

    super
  end

  def object_type
    ::Ticket
  end

  def accounted_time_type_options
    {
      value:   Setting.get('time_accounting_type_default'),
      options: ::Ticket::TimeAccounting::Type.where(active: true).map do |type|
        {
          value: type.id,
          label: type.name,
        }
      end,
    }
  end
end
