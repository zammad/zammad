# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::StoresTaskbarState
  extend ActiveSupport::Concern

  class_methods do
    def store_state_collect_group_key(group_key)
      @store_state_collect_group_key ||= group_key
    end

    def store_state_group_keys(group_keys)
      @store_state_group_keys ||= group_keys
    end

    # Store the initial round trip too, which is otherwise left alone. A form over an existing
    #   object resolves that object's own values there, and storing them would turn every opened
    #   tab into a draft of nothing. A create screen has no object to fall back on: what its first
    #   round trip resolves *is* the draft - including whatever the client seeded it with, which
    #   the tab cannot work out for itself, since the link it is reopened through carries no query.
    def store_state_on_initial
      @store_state_on_initial = true
    end
  end

  attr_reader :applied_field_from_group_key

  def initialize(**)
    @applied_field_from_group_key = {}

    super
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
    store_state_collect_group_key = self.class.instance_variable_get(:@store_state_collect_group_key)
    store_state_group_keys = self.class.instance_variable_get(:@store_state_group_keys)

    store_value = FormUpdater::StoreValue.new(store_state_group_keys)

    state = {
      form_id: meta[:form_id],
    }

    if store_state_collect_group_key.present?
      state[store_state_collect_group_key] = {}
    end

    prepared_data.each_pair do |field, value|
      next if !should_store_field?(field, value, store_state_group_keys)

      field_state = store_value.perform(field:, value:)

      if store_state_collect_group_key.present? && (store_state_group_keys.blank? || store_state_group_keys.exclude?(field))
        state[store_state_collect_group_key] = state[store_state_collect_group_key].merge field_state
      else
        state = state.merge field_state
      end
    end

    after_store_taskbar_preperation(state) if self.class.method_defined?(:after_store_taskbar_preperation)

    current_taskbar.update!(state:)
  end

  def prepared_data
    # Iterate through the result hash and merge values.
    result.each do |key, value|
      # Only process fields that have a 'value' key.
      next if !value.key?(:value)

      if applied_field_from_group_key.key?(key)
        parent_key = applied_field_from_group_key[key]

        data[parent_key] ||= {}
        data[parent_key][key] = value[:value]
      else
        data[key] = value[:value]
      end
    end

    data
  end

  # Memoized including nil, like its twin in AppliesTaskbarState - whichever of the two ends up
  #   answering, the store path reads it several times per round trip.
  def current_taskbar
    return @current_taskbar if defined?(@current_taskbar)

    id = meta.dig(:additional_data, 'taskbarId')

    @current_taskbar = id.present? ? Gql::ZammadSchema.authorized_object_from_id(id, type: Taskbar, user: context[:current_user]) : nil
  end

  def should_store_field?(field, value, store_state_group_keys)
    # When no object already exists, we can ignore the check, then we save all values from the form.
    return true if object.blank?

    # State groups are always stored and the sub fields are checked separately.
    return true if store_state_group_keys&.include?(field)

    # Return always true, when field does not exists on object, because we need always to store the value.
    return true if !object_field?(field)

    object_value = object_field_value(field)

    # When current object field is empty and the value is empty, then we don't need to store the value.
    return false if object_value.blank? && value.blank?

    object_field_changed?(field, value)
  end

  def should_store?
    return false if meta.dig(:additional_data, 'applyTaskbarState') == true
    return true if !meta[:initial]

    # Only into a fresh tab: a draft that has been worked on already holds everything this round
    #   trip would write, and the values it was opened with are the ones it must not fall back to.
    store_state_on_initial? && current_taskbar.state.blank?
  end

  def store_state_on_initial?
    self.class.instance_variable_get(:@store_state_on_initial).present?
  end
end
