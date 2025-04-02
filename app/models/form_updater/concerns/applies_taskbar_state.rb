# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::AppliesTaskbarState
  extend ActiveSupport::Concern

  SKIP_FIELDS = %w[attachments].freeze

  class_methods do
    def apply_state_group_keys(group_keys)
      @apply_state_group_keys ||= group_keys
    end
  end

  def resolve
    if current_taskbar.present? && should_apply?
      apply_taskbar_state
    end

    super
  end

  private

  def apply_taskbar_state
    apply_value = FormUpdater::ApplyValue.new(context:, data:, result:)

    apply_state_group_keys = self.class.instance_variable_get(:@apply_state_group_keys)

    current_taskbar.state.each_pair do |field, value|
      next if SKIP_FIELDS.include?(field)

      if apply_state_group_keys.present? && apply_state_group_keys.include?(field) && value.is_a?(Hash)
        value.each_pair do |sub_field, sub_value|
          next if SKIP_FIELDS.include?(sub_field)

          apply_value.perform(field: sub_field, config: { 'value' => sub_value }, include_blank: true, parent_field: field)
        end
      else
        apply_value.perform(field: field, config: { 'value' => value }, include_blank: true)
      end
    end

    # When no object exists, we can ignore the additional check.
    return if object.blank?

    apply_taskbar_object_defaults(apply_value)
  end

  def apply_taskbar_object_defaults(apply_value)
    apply_state_group_keys = self.class.instance_variable_get(:@apply_state_group_keys)

    # We need to check the current dirty fields, to restore maybe some default value from the current ticket.
    meta[:dirty_fields]&.each do |field|
      next if SKIP_FIELDS.include?(field)

      # Check first on the first level if it's present in the current state.
      next if current_taskbar.state.key?(field)

      next if apply_state_group_keys.present? && apply_state_group_keys.any? { |group_key| current_taskbar.state[group_key]&.key?(field) }

      next if !object.respond_to?(field)
      next if object[field] == data[field]

      apply_value.perform(field: field, config: { 'value' => object[field] }, include_blank: true)
    end
  end

  def current_taskbar
    id = meta.dig(:additional_data, 'taskbarId')
    Gql::ZammadSchema.authorized_object_from_id(id, type: Taskbar, user: context[:current_user]) if id.present?
  end

  def should_apply?
    meta.dig(:additional_data, 'applyTaskbarState') == true || meta[:initial]
  end
end
