# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::StoresTaskbarState
  extend ActiveSupport::Concern

  class_methods do
    def store_state_group_key(group_key)
      @store_state_group_key ||= group_key
    end

    def store_state_group_skip_keys(skip_keys)
      @store_state_group_skip_keys ||= skip_keys
    end
  end

  def resolve
    resolved_result = super

    # Store handling needs to be done after all the other processing is over (so the result is present).
    if current_taskbar.present? && should_store?
      store_taskbar_state
    end

    resolved_result
  end

  private

  def store_taskbar_state
    store_state_group_key = self.class.instance_variable_get(:@store_state_group_key)
    store_state_group_skip_keys = self.class.instance_variable_get(:@store_state_group_skip_keys)

    store_value = FormUpdater::StoreValue.new(store_state_group_skip_keys)

    state = {
      form_id: meta[:form_id],
    }

    if store_state_group_key.present?
      state[store_state_group_key] = {}
    end

    prepared_data.each_pair do |field, value|
      field_state = store_value.perform(field:, value:)

      if store_state_group_key.present? && (store_state_group_skip_keys.blank? || store_state_group_skip_keys.exclude?(field))
        state[store_state_group_key] = state[store_state_group_key].merge field_state
      else
        state = state.merge field_state
      end
    end

    after_store_taskbar_preperation(state) if self.class.method_defined?(:after_store_taskbar_preperation)

    current_taskbar.update!(state:, skip_trigger: true)
  end

  def prepared_data
    # Iterate through the result hash and merge values.
    result.each do |key, value|
      # Only process fields that have a 'value' key.
      next if !value.key?(:value)

      data[key] = value[:value]
    end

    data
  end

  def current_taskbar
    id = meta.dig(:additional_data, 'taskbarId')
    return if id.blank?

    Gql::ZammadSchema.authorized_object_from_id(id, type: Taskbar, user: context[:current_user])
  end

  def should_store?
    meta.dig(:additional_data, 'applyTaskbarState') != true && !meta[:initial]
  end
end
