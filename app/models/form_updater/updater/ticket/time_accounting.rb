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
    active_types = ::Ticket::TimeAccounting::Type.where(active: true).to_a

    # An empty type list would only render an empty select, so the field stays hidden until
    #   there is at least one active type to pick from. The configured default may have been
    #   deactivated in the meantime, in which case nothing gets pre-selected.
    default_type = active_types.find { |type| type.id == Setting.get('time_accounting_type_default') }

    {
      show:    Setting.get('time_accounting_types').present? && active_types.any?,
      value:   default_type&.id,
      options: active_types.map do |type|
        {
          value: type.id,
          label: type.name,
        }
      end,
    }
  end
end
