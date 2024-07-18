# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::AppliesTaskbarState
  extend ActiveSupport::Concern

  def resolve
    if current_taskbar.present? && should_apply?
      apply_taskbar_state
    end

    super
  end

  private

  def apply_taskbar_state
    apply_value = FormUpdater::ApplyValue.new(context:, data:, meta:, result:)

    current_taskbar.state.each_pair do |field, value|
      apply_value.perform(field: field, config: { 'value' => value }, include_blank: true)
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
