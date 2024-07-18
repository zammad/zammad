# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::StoresTaskbarState
  extend ActiveSupport::Concern

  def resolve
    if current_taskbar.present? && should_store?
      store_taskbar_state
    end

    super
  end

  private

  def store_taskbar_state
    store_value = FormUpdater::StoreValue.new

    # TODO: This will not work for ticket detail view, we have two forms there and we cannot overwrite the state completely.

    state = {
      form_id: meta[:form_id],
    }

    data.each_pair do |field, value|
      field_state = store_value.perform(field:, value:)
      state = state.merge field_state
    end

    # TODO: Skip trigger, but not for ticket create.
    # if current_taskbar.callback != 'TicketCreate' ...
    current_taskbar.skip_trigger = true

    current_taskbar.update!(state:)
  end

  def current_taskbar
    id = meta.dig(:additional_data, 'taskbarId')
    Gql::ZammadSchema.authorized_object_from_id(id, type: Taskbar, user: context[:current_user]) if id.present?
  end

  def should_store?
    meta.dig(:additional_data, 'applyTaskbarState') != true && !meta[:initial]
  end
end
